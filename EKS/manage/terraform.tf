terraform {
  cloud {
    organization = "PEACEHAVENCORP"
    workspaces {
      name = "terraform-jenkins-EKS-manage"
    }
  }
}