# AKS Hello World

A hands-on DevOps learning project that takes a simple Python Flask app all the way from local code to a running workload on Azure Kubernetes Service (AKS).

## What this project covers

- Building a small cloud-native web app with health checks and config from environment variables
- Containerizing it with Docker (Rancher Desktop)
- Provisioning Azure Container Registry (ACR) and AKS with Terraform
- Deploying to Kubernetes with manifests
- Automating test, build, push and deploy with GitHub Actions using OIDC

## Repository structure

| Folder | Purpose |
|---|---|
| `app/` | Flask application, tests and Dockerfile |
| `infra/` | Terraform for ACR and AKS |
| `k8s/` | Kubernetes manifests |
| `.github/workflows/` | CI/CD pipelines |

## Progress

- [x] Phase 1 – Local container environment (Rancher Desktop)
- [ ] Phase 2 – Hello World app running locally
- [ ] Phase 3 – Containerize the app
- [ ] Phase 4 – ACR and AKS with Terraform
- [ ] Phase 5 – Deploy to AKS
- [ ] Phase 6 – CI/CD with GitHub Actions