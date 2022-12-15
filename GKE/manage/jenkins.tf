resource "helm_release" "jenkins" {
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
  metadata {
    name = "jenkins"

    labels = {
      name        = "jenkins"
      description = "jenkins"
    }
  }
}
