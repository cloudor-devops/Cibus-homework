# GitOps-Driven Deployment on Local Workspace

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Helm](https://helm.sh/docs/intro/install/)

## Repository Structure

```
.
├── app/                  # Python REST API source code
│   ├── app.py
│   └── requirements.txt
├── Dockerfile            # Production-ready, non-root container image
├── k8s/                  # Kubernetes manifests (managed by ArgoCD)
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── terraform/            # IaC for cluster resource provisioning
│   ├── providers.tf
│   ├── variables.tf
│   ├── namespace.tf
│   ├── tls.tf
│   ├── argocd.tf
│   └── argocd-app.tf
└── architecture.md       # System architecture diagram
```

## Setup Instructions

### 1. Start Minikube

```bash
minikube start --driver=docker
minikube addons enable ingress
minikube addons enable metrics-server
```

### 2. Build the Application Image

Load the image directly into minikube's Docker daemon:

```bash
eval $(minikube docker-env)
docker build -t task-app:latest .
```

### 3. Provision Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform apply
```

This creates:
- `production` namespace
- Self-signed TLS certificate + Kubernetes Secret
- ArgoCD (via Helm) in the `argocd` namespace
- ArgoCD Application CR pointing to the `k8s/` directory in this repo

### 4. Configure Local DNS

Add the minikube IP to your hosts file:

```bash
echo "$(minikube ip) task-app.local" | sudo tee -a /etc/hosts
```

### 5. Verify the Deployment

Check ArgoCD status:

```bash
kubectl get applications -n argocd
```

Retrieve the ArgoCD admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Access the ArgoCD UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8443:443
# Open https://localhost:8443 (user: admin)
```

Test the API:

```bash
curl -k https://task-app.local/
```

Verify HTTP-to-HTTPS redirect:

```bash
curl -I http://task-app.local/
# Expected: 308 redirect to https://task-app.local/
```
