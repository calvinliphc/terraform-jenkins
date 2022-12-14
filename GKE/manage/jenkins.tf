resource "helm_release" "jenkins" {
  provider = helm.primary

  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "3.6.0"
  namespace  = "jenkins"
  timeout    = 600
  values = [
    file("../../values.yaml"),
  ]

  depends_on = [
    kubernetes_namespace.jenkins,
  ]
}

resource "kubernetes_namespace" "jenkins" {
  provider = kubernetes.primary
  metadata {
    name = "jenkins"

    labels = {
      name        = "jenkins"
      description = "jenkins"
    }
  }
}
