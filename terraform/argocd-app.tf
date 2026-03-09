resource "kubernetes_manifest" "argocd_app" {
  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "task-app"
      namespace = "argocd"
    }

    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/cloudor-devops/task-app-homework.git"
        targetRevision = "HEAD"
        path           = "k8s"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "production"
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}
