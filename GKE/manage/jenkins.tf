provider "helm" {
#  tiller_image = "gcr.io/kubernetes-helm/tiller:${var.helm_version}"

  kubernetes {
    host                   = "${data.google_container_cluster.my_cluster.endpoint}"
    token                  = "${data.google_client_config.default.access_token}"
    client_certificate     = "${base64decode(data.google_container_cluster.my_cluster.master_auth.0.client_certificate)}"
    client_key             = "${base64decode(data.google_container_cluster.my_cluster.master_auth.0.client_key)}"
    cluster_ca_certificate = "${base64decode(data.google_container_cluster.my_cluster.master_auth.0.cluster_ca_certificate)}"
  }
}

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
