# System Architecture Diagram

```
                        +--------------------------+
                        |      Developer / Git     |
                        |  (Push to GitHub repo)   |
                        +------------+-------------+
                                     |
                                     | monitors repo (GitOps)
                                     v
+--------------------------------------------------------------------------+
|  Minikube Cluster (Docker driver)                                        |
|                                                                          |
|  +---------------------------+     +----------------------------------+  |
|  |  argocd namespace         |     |  production namespace            |  |
|  |                           |     |                                  |  |
|  |  +---------------------+  |     |  +----------------------------+  |  |
|  |  |   ArgoCD Server     |--+---->|  |  Deployment (task-app)     |  |  |
|  |  |  (auto-sync k8s/)   |  |     |  |  - 2 replicas (min)       |  |  |
|  |  +---------------------+  |     |  |  - RollingUpdate strategy  |  |  |
|  +---------------------------+     |  |  - Liveness/readiness      |  |  |
|                                    |  |    probes (/healthz)       |  |  |
|  +---------------------------+     |  |  - CPU/memory limits       |  |  |
|  |  ingress-nginx namespace  |     |  |  - securityContext         |  |  |
|  |                           |     |  |    (nonRoot, readOnly,     |  |  |
|  |  +---------------------+  |     |  |     no privilege esc.)     |  |  |
|  |  | NGINX Ingress       |  |     |  +----------------------------+  |  |
|  |  | Controller          |  |     |                                  |  |
|  |  +---------------------+  |     |  +----------------------------+  |  |
|  +---------------------------+     |  |  ServiceAccount (task-app)  |  |  |
|                                    |  |  - automountToken: false    |  |  |
|                                    |  +----------------------------+  |  |
|                                    |                                  |  |
|                                    |  +----------------------------+  |  |
|                                    |  |  HPA                       |  |  |
|                                    |  |  - min: 2, max: 5 replicas |  |  |
|                                    |  |  - CPU 70% / Memory 80%    |  |  |
|                                    |  +----------------------------+  |  |
|                                    |                                  |  |
|                                    |  +----------------------------+  |  |
|                                    |  |  PodDisruptionBudget       |  |  |
|                                    |  |  - minAvailable: 1         |  |  |
|                                    |  +----------------------------+  |  |
|                                    |                                  |  |
|                                    |  +----------------------------+  |  |
|                                    |  |  NetworkPolicy             |  |  |
|                                    |  |  - ingress from nginx only |  |  |
|                                    |  +----------------------------+  |  |
|                                    |                                  |  |
|                                    |  +------------+  +------------+  |  |
|                                    |  |  Service   |  | TLS Secret |  |  |
|                                    |  | :80 -> 8080|  | (self-sign)|  |  |
|                                    |  +------+-----+  +------+-----+  |  |
|                                    |         |               |        |  |
|                                    |  +------v---------------v------+ |  |
|                                    |  |  Ingress (nginx)            | |  |
|                                    |  |  - TLS termination          | |  |
|                                    |  |  - HTTP 80 -> HTTPS 443     | |  |
|                                    |  +-----------------------------+ |  |
|                                    +----------------------------------+  |
|                                              |                           |
+----------------------------------------------+---------------------------+
                                               |
                                     https://task-app.local
                                               |
                                          +----v----+
                                          |  User   |
                                          +---------+
```

## Flow

1. **Developer** pushes code/manifests to the GitHub repository.
2. **Terraform** provisions the cluster infrastructure: namespaces, TLS secret, ArgoCD (via Helm), and the ArgoCD Application CR.
3. **ArgoCD** watches the `k8s/` directory in the repo and auto-syncs all resources to the `production` namespace.
4. **Ingress** (NGINX) terminates TLS using the self-signed certificate and redirects HTTP to HTTPS.
5. **User** accesses the API at `https://task-app.local`.

## High Availability & Security

- **HPA** auto-scales pods (2-5) based on CPU/memory utilization, backed by metrics-server.
- **PodDisruptionBudget** guarantees at least 1 pod remains available during voluntary disruptions (node drains, upgrades).
- **Rolling update** strategy with `maxUnavailable: 0` ensures zero-downtime deployments.
- **Liveness/readiness probes** on `/healthz` enable Kubernetes to detect and replace unhealthy pods.
- **Resource requests/limits** prevent runaway resource consumption.
- **SecurityContext** enforces non-root, read-only filesystem, and no privilege escalation.
- **Dedicated ServiceAccount** with `automountServiceAccountToken: false` removes unnecessary K8s API access.
- **NetworkPolicy** restricts pod ingress to traffic from the NGINX ingress controller only.
