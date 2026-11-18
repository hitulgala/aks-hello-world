# ==============================================================================
# dev-centralindia  |  ALL deployment values live in this file.
# Values marked "<--" must be changed by anyone deploying this repo themselves.
#
# IDs are NOT set here:
#   locally -> ids.auto.tfvars (git-ignored; copy ids.auto.tfvars.example)
#   in CI   -> GitHub repository variables, passed as TF_VAR_*
#
# IP plan:  VNet 10.20.0.0/16 | pods (overlay) 10.244.0.0/16 | services 10.0.0.0/16
# ==============================================================================

location = "centralindia"

# ------------------------------------------------------------------ Tags
# Every name in mandatory_tag_names must have a value in 'tags', or plan fails.
mandatory_tag_names = ["environment", "workload", "owner", "cost_center", "managed_by"]

tags = {
  environment = "dev"
  workload    = "aks-hello-world"
  owner       = "platform-team@example.com" # <--
  cost_center = "learning"
  managed_by  = "terraform"
}

# ------------------------------------------------------------------ Resource group
resource_group_name = "rg-helloaks-dev-cin-001"

# ------------------------------------------------------------------ Network
network = {
  vnet_name     = "vnet-helloaks-dev-cin-001"
  address_space = ["10.20.0.0/16"]

  subnets = {
    # Key "aks" is referenced by aks.subnet_key below.
    # With CNI Overlay only NODES use subnet IPs, so a /24 is plenty.
    aks = {
      name             = "snet-aks-001"
      address_prefixes = ["10.20.1.0/24"]
    }
  }
}

# ------------------------------------------------------------------ Container registry
container_registry = {
  name          = "acrhelloaksdevcin001" # <-- globally unique, letters and digits only
  sku           = "Basic"
  admin_enabled = false
}

# ------------------------------------------------------------------ AKS
aks = {
  name       = "aks-helloaks-dev-cin-001"
  dns_prefix = "aks-helloaks-dev-cin-001"

  # Created and owned by AKS (VMs, disks, load balancer). Never edit it by hand.
  node_resource_group_name = "rg-helloaks-dev-nodes-cin-001"

  subnet_key = "aks"

  # Free = no control-plane cost and no SLA
  sku_tier = "Free"

  # kubernetes_version not set = AKS default version; "patch" keeps it patched
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"
  local_account_disabled    = true

  default_node_pool = {
    name                        = "system"
    vm_size                     = "Standard_B2as_v2" # 2 vCPU / 4 GB: AKS minimum, burstable = cheap
    node_count                  = 1
    os_disk_size_gb             = 30
    temporary_name_for_rotation = "systemtmp"
    max_surge                   = "10%"
  }

  network_profile = {
    pod_cidr       = "10.244.0.0/16"
    service_cidr   = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10" # must be inside service_cidr
  }
}
