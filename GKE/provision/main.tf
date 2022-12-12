terraform {
    cloud {
        organization = "PEACEHAVENCORP"
        workspaces {
            name = "terraform-jenkins-GKE-provision"
        }
    }
}