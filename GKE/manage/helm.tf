provider "helm" {
  kubernetes {
    host                   = "${data.google_container_cluster.my_cluster.endpoint}"
    token                  = "${data.google_client_config.default.access_token}"
    client_certificate     = "${base64decode(data.google_container_cluster.my_cluster.master_auth.0.client_certificate)}"
    client_key             = "${base64decode(data.google_container_cluster.my_cluster.master_auth.0.client_key)}"
    cluster_ca_certificate = "${base64decode(data.google_container_cluster.my_cluster.master_auth.0.cluster_ca_certificate)}"
  }
}