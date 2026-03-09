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
|  |  +---------------------+  |     |  +------------+  +------------+ |  |
|  |  |     ArgoCD Server   |--+---->|  | Deployment |  |  TLS Secret| |  |
|  |  |  (auto-sync k8s/)   |  |     |  | task-app  |  | task-app-tls  | |  |
|  |  +---------------------+  |     |  |  (x1 pod) |  +------------+ |  |
|  +---------------------------+     |  +------+-----+        |        |  |
|                                    |         |              |        |  |
|                                    |  +------v-----+        |        |  |
|                                    |  |  Service   |        |        |  |
|                                    |  | :80 -> 8080|        |        |  |
|                                    |  +------+-----+        |        |  |
|                                    |         |              |        |  |
|                                    |  +------v--------------v------+ |  |
|                                    |  |  Ingress (nginx)           | |  |
|                                    |  |  - TLS termination         | |  |
|                                    |  |  - HTTP 80 -> HTTPS 443   | |  |
|                                    |  +----------------------------+ |  |
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
3. **ArgoCD** watches the `k8s/` directory in the repo and auto-syncs Deployment, Service, and Ingress to the `production` namespace.
4. **Ingress** (NGINX) terminates TLS using the self-signed certificate and redirects HTTP to HTTPS.
5. **User** accesses the API at `https://task-app.local`.
