<#
.SYNOPSIS
    Creates (or repairs) the Azure Storage backend for Terraform state and writes
    backend.hcl into each stack folder.

.DESCRIPTION
    Terraform cannot create the storage account that holds its own state, so this
    script does it once, outside Terraform. It is idempotent: every run checks what
    exists, creates what is missing and re-applies the security settings, so it is
    safe to run again at any time (locally or from a GitHub Actions workflow).

    What it ensures:
      1. Resource group for the state
      2. Storage account: TLS 1.2, HTTPS only, no public blob access,
         NO shared keys (Entra ID + RBAC only)
      3. Blob versioning + soft delete (recover a broken or deleted state file)
      4. Blob container for the state files
      5. 'Storage Blob Data Contributor' for the identity running Terraform
      6. CanNotDelete lock on the storage account
      7. backend.hcl in every stack folder (git-ignored)

    Requires the Az PowerShell modules Az.Accounts, Az.Resources and Az.Storage,
    and an existing login (Connect-AzAccount).

.EXAMPLE
    Connect-AzAccount
    .\infra\scripts\Bootstrap-TerraformBackend.ps1 `
        -SubscriptionId     "00000000-0000-0000-0000-000000000000" `
        -ResourceGroupName  "rg-helloaks-tfstate-cin" `
        -StorageAccountName "sthelloakstfcin01"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SubscriptionId,

    [Parameter(Mandatory)]
    [string] $ResourceGroupName,

    # 3-24 characters, lowercase letters and digits only, globally unique
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9]{3,24}$')]
    [string] $StorageAccountName,

    [string] $Location = 'centralindia',

    [string] $ContainerName = 'tfstate',

    # Stack folders (relative to infra/) that get a backend.hcl
    [string[]] $Stacks = @('dev-centralindia'),

    # State file name = <prefix>-<stack>.tfstate
    [string] $StateKeyPrefix = 'aks-hello-world',

    # Object ID that gets data access to the state. Empty = the logged-in identity.
    # Pass it explicitly in CI if the pipeline identity cannot read Entra ID.
    [string] $PrincipalObjectId,

    [hashtable] $Tags = @{
        environment = 'shared'
        workload    = 'aks-hello-world'
        purpose     = 'terraform-state'
        managed_by  = 'bootstrap-script'
        cost_center = 'CC-0000'
        owner       = 'platform-team@example.com'
    }
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step([string] $Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

# ------------------------------------------------------------------ 0. Prerequisites
foreach ($module in 'Az.Accounts', 'Az.Resources', 'Az.Storage') {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        throw "PowerShell module '$module' is missing. Install it with: Install-Module $module -Scope CurrentUser"
    }
}
if (-not (Get-AzContext)) {
    throw 'Not logged in to Azure. Run Connect-AzAccount first.'
}

Write-Step "Selecting subscription $SubscriptionId"
$null = Set-AzContext -Subscription $SubscriptionId

# ------------------------------------------------------------------ 1. Resource group
Write-Step "Resource group '$ResourceGroupName'"
$rg = Get-AzResourceGroup | Where-Object ResourceGroupName -EQ $ResourceGroupName
if (-not $rg) {
    $null = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
    Write-Host '    created'
}
else {
    Write-Host '    already exists'
}

# ------------------------------------------------------------------ 2. Storage account
Write-Step "Storage account '$StorageAccountName'"
$sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName |
Where-Object StorageAccountName -EQ $StorageAccountName

if (-not $sa) {
    $availability = Get-AzStorageAccountNameAvailability -Name $StorageAccountName
    if (-not $availability.NameAvailable) {
        throw "Storage account name '$StorageAccountName' is not available: $($availability.Message)"
    }

    $sa = New-AzStorageAccount `
        -ResourceGroupName      $ResourceGroupName `
        -Name                   $StorageAccountName `
        -Location               $Location `
        -SkuName                Standard_LRS `
        -Kind                   StorageV2 `
        -MinimumTlsVersion      TLS1_2 `
        -EnableHttpsTrafficOnly $true `
        -AllowBlobPublicAccess  $false `
        -AllowSharedKeyAccess   $false `
        -Tag                    $Tags
    Write-Host '    created'
}
else {
    # Re-apply the security baseline in case someone changed it in the portal
    $sa = Set-AzStorageAccount `
        -ResourceGroupName      $ResourceGroupName `
        -Name                   $StorageAccountName `
        -MinimumTlsVersion      TLS1_2 `
        -EnableHttpsTrafficOnly $true `
        -AllowBlobPublicAccess  $false `
        -AllowSharedKeyAccess   $false `
        -Force
    Write-Host '    already exists - security settings re-applied'
}

# ------------------------------------------------------------------ 3. Versioning + soft delete
Write-Step 'Blob versioning and soft delete'
$null = Update-AzStorageBlobServiceProperty `
    -ResourceGroupName  $ResourceGroupName `
    -StorageAccountName $StorageAccountName `
    -IsVersioningEnabled $true
$null = Enable-AzStorageBlobDeleteRetentionPolicy `
    -ResourceGroupName  $ResourceGroupName `
    -StorageAccountName $StorageAccountName `
    -RetentionDays 14
Write-Host '    enabled (14-day soft delete)'

# ------------------------------------------------------------------ 4. Container
# Created through Azure Resource Manager (the *-AzRm* cmdlets), so it works before
# any data-plane role has propagated and without shared keys.
Write-Step "Container '$ContainerName'"
$container = Get-AzRmStorageContainer -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName |
Where-Object Name -EQ $ContainerName
if (-not $container) {
    $null = New-AzRmStorageContainer `
        -ResourceGroupName  $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -Name               $ContainerName `
        -PublicAccess       None
    Write-Host '    created'
}
else {
    Write-Host '    already exists'
}

# ------------------------------------------------------------------ 5. Data access for Terraform
Write-Step 'Role assignment: Storage Blob Data Contributor'
if (-not $PrincipalObjectId) {
    $account = (Get-AzContext).Account
    if ($account.Type -eq 'User') {
        $PrincipalObjectId = (Get-AzADUser -SignedIn).Id
    }
    else {
        # Service principal / managed identity (e.g. GitHub Actions with OIDC)
        $PrincipalObjectId = (Get-AzADServicePrincipal -ApplicationId $account.Id).Id
    }
}

$roleName = 'Storage Blob Data Contributor'
$existing = Get-AzRoleAssignment -ObjectId $PrincipalObjectId -RoleDefinitionName $roleName -Scope $sa.Id -ErrorAction SilentlyContinue |
Where-Object Scope -EQ $sa.Id
if (-not $existing) {
    $null = New-AzRoleAssignment -ObjectId $PrincipalObjectId -RoleDefinitionName $roleName -Scope $sa.Id
    Write-Host "    assigned to $PrincipalObjectId (allow 1-5 minutes to propagate)"
}
else {
    Write-Host "    already assigned to $PrincipalObjectId"
}

# ------------------------------------------------------------------ 6. Delete lock
Write-Step 'Resource lock: CanNotDelete'
$lockName = "lock-$StorageAccountName-nodelete"
$lock = Get-AzResourceLock -ResourceGroupName $ResourceGroupName -ResourceName $StorageAccountName `
    -ResourceType 'Microsoft.Storage/storageAccounts' -ErrorAction SilentlyContinue |
Where-Object Name -EQ $lockName
if (-not $lock) {
    $null = New-AzResourceLock `
        -LockName          $lockName `
        -LockLevel         CanNotDelete `
        -LockNotes         'Holds Terraform state. Remove this lock only to retire the project.' `
        -ResourceGroupName $ResourceGroupName `
        -ResourceName      $StorageAccountName `
        -ResourceType      'Microsoft.Storage/storageAccounts' `
        -Force
    Write-Host '    created'
}
else {
    Write-Host '    already exists'
}

# ------------------------------------------------------------------ 7. backend.hcl per stack
Write-Step 'Writing backend.hcl'
$infraRoot = Split-Path -Parent $PSScriptRoot
foreach ($stack in $Stacks) {
    $stackPath = Join-Path $infraRoot $stack
    if (-not (Test-Path $stackPath)) {
        throw "Stack folder not found: $stackPath"
    }

    $content = @(
        '# Generated by scripts/Bootstrap-TerraformBackend.ps1 - do not commit (git-ignored).'
        "subscription_id      = `"$SubscriptionId`""
        "resource_group_name  = `"$ResourceGroupName`""
        "storage_account_name = `"$StorageAccountName`""
        "container_name       = `"$ContainerName`""
        "key                  = `"$StateKeyPrefix-$stack.tfstate`""
        'use_azuread_auth     = true'
        ''
    ) -join "`n"

    # UTF-8 without BOM and LF line endings, which Terraform parses on every OS
    $backendFile = Join-Path $stackPath 'backend.hcl'
    [System.IO.File]::WriteAllText($backendFile, $content)
    Write-Host "    $backendFile"
}

Write-Host ''
Write-Host 'Backend ready. Next:' -ForegroundColor Green
Write-Host "  cd infra\$($Stacks[0])"
Write-Host '  terraform init -backend-config="backend.hcl"'
