resource "tls_private_key" "ingress" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ingress" {
  private_key_pem = tls_private_key.ingress.private_key_pem

  subject {
    common_name  = "task-app.local"
    organization = "Task"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "kubernetes_secret" "tls" {
  metadata {
    name      = "task-app-tls"
    namespace = kubernetes_namespace.production.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.ingress.cert_pem
    "tls.key" = tls_private_key.ingress.private_key_pem
  }
}
