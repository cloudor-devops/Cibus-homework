resource "kubernetes_namespace" "production" {
  metadata {
    name = "production"
  }
}
