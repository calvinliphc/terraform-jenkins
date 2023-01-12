## EKS Resources

data "terraform_remote_state" "eks" {
  backend = "remote"
  config = {
    organization = "PEACEHAVENCORP"
    workspaces = {
      name = "terraform-jenkins-EKS-provision"
    }
  }
}
provider "aws" {
  region = data.terraform_remote_state.eks.outputs.region
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
    command     = "aws"
  }

  experiments {
    manifest_resource = true
  }
}

provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

resource "helm_release" "consul_dc1" {
  provider   = helm.eks
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  version    = "1.0.2"

  values = [
    file("dc1.yaml")
  ]
}

data "kubernetes_secret" "eks_federation_secret" {
  provider = kubernetes.eks
  metadata {
    name = "consul-federation"
  }

  depends_on = [helm_release.consul_dc1]
}

## GKE Resources

data "terraform_remote_state" "gke" {
  backend = "remote"
  config = {
    organization = "PEACEHAVENCORP"
    workspaces = {
      name = "terraform-jenkins-GKE-provision"
    }
  }
}

# Retrieve GKE cluster information
provider "google" {
  project = data.terraform_remote_state.gke.outputs.project_id
  region  = data.terraform_remote_state.gke.outputs.region
}

# Configure kubernetes provider with Oauth2 access token.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# This fetches a new token, which will expire in 1 hour.
data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
  name     = data.terraform_remote_state.gke.outputs.kubernetes_cluster_name
  location = data.terraform_remote_state.gke.outputs.region
}

provider "kubernetes" {
  alias = "gke"
  host = "https://${data.terraform_remote_state.gke.outputs.kubernetes_cluster_host}"

  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)

  experiments {
    manifest_resource = true
  }
}

provider "helm" {
  alias = "gke"
  kubernetes {
    host                   = "${data.google_container_cluster.my_cluster.endpoint}"
    token                  = "${data.google_client_config.default.access_token}"
    client_certificate     = "${base64decode(data.google_container_cluster.my_cluster.master_auth.0.client_certificate)}"
    client_key             = "${base64decode(data.google_container_cluster.my_cluster.master_auth.0.client_key)}"
    cluster_ca_certificate = "${base64decode(data.google_container_cluster.my_cluster.master_auth.0.cluster_ca_certificate)}"
  }
}

resource "kubernetes_secret" "gke_federation_secret" {
  provider = kubernetes.gke
  metadata {
    name = "consul-federation"
  }

  data = data.kubernetes_secret.eks_federation_secret.data
}


resource "helm_release" "consul_dc2" {
  provider   = helm.gke
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  version    = "1.0.2"

  values = [
    file("dc2.yaml")
  ]

  depends_on = [kubernetes_secret.gke_federation_secret]
}
