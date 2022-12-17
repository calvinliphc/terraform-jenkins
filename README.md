# terraform-jenkins

This project aims to use Terraform to deploy Jenkins to each of the 3 main cloud providers (AWS, GCP, Azure).


# Deploying Jenkins to Kubernetes on the Cloud (AWS, GCP, Azure) using Terraform

This document describes the process of using Terraform to deploy Jenkins onto a Kubernetes cluster on each of the 3 major cloud providers’ managed Kubernetes services.

Example code for this project can be found at:
https://github.com/calvinliphc/terraform-jenkins


## Section 1: GCP - Google Kubernetes Engine (GKE)

Follow the companion article for this project at: https://medium.com/@calvintianli/deploying-jenkins-to-kubernetes-on-the-cloud-aws-gcp-azure-using-terraform-f00096e929e

Begin by following the tutorials below to use Terraform to set up a basic Kubernetes cluster on GKE. The first tutorial creates Terraform configurations for provisioning a GKE cluster, while the second tutorial contains a different set of configurations, placed in its own directory, which manages the existing GKE cluster.

https://developer.hashicorp.com/terraform/tutorials/kubernetes/gke

https://developer.hashicorp.com/terraform/tutorials/kubernetes/kubernetes-provider

The resulting directory structure of your Terraform code should look something like:

```
terraform-project/  
  manage/  
    …  
  provision/  
    …  
```

The configuration in the `manage` directory references the Terraform state from the `provision` directory.

Once you have gone through those two tutorials, you should be able to provision a Kubernetes cluster to GKE using the local Terraform CLI, as well as deploy services such as nginx to the cluster and even monitor the cluster using kubectl locally. 

**NOTE**: If you are having issues with quotas such as “resource "SSD_TOTAL_GB": request requires '600.0' and is short '100.0'. project has a quota of '500.0' with '500.0' available”
Try changing the region in the terraform.tfvars file of your project

### Next, you can try to create a Terraform Cloud Workspace for the provisioning directory and then import the local Terraform state onto Terraform Cloud.

  * On your Terraform Cloud account console, create a new workspace and link it to the VCS (probably GitHub) repository for your project. 

  * Then, go to the workspace settings and under General, set the “Working Directory” to the directory where the configurations for provisioning the GKE cluster are located.


The below tutorial describes how to migrate the existing local backend/state onto your Terraform Cloud workspace.

https://developer.hashicorp.com/terraform/tutorials/cloud/cloud-migrate


Next, you need to connect your Google Cloud credentials to the Terraform Workspace.

https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#adding-credentials

https://support.hashicorp.com/hc/en-us/articles/4406586874387-How-to-set-up-Google-Cloud-GCP-credentials-in-Terraform-Cloud

Either of the above two links should tell you what you need to know. Basically:
  * generate your GCP service account key pair json file.
  * remove the newline characters from that file 
    * I even created a little Python script to do this: https://github.com/calvinli723/useful-python-scripts/blob/main/rm_newlines.py
  * Use the contents of the stripped file as the value for a new environment variable in your Terraform Cloud workspace. Save the contents into its own file as we will be using it again later
  * Use “GOOGLE_CREDENTIALS” as the key for the variable, and mark it as sensitive

### You should now be able to use Terraform Cloud to plan/apply your configuration as well as store the state for your GKE provisioning configurations.

### Next, modify the configuration in the manage directory by pointing it to the new Cloud backend instead of the local backend from the provisioning directory.

* This means that in the `kubernetes.tf` file in the manage directory, under the `terraform_remote_state` data source, use a remote backend instead and put the Terraform Cloud organization and workspace information in the config.

* Then, in the Terraform Cloud console, navigate to the provisioning workspace and go to *Settings > General*

* Then select the workspace for managing the cluster to share the state with it


Finally, you actually want to migrate the GCP credentials from a *Variable* to a *Variable Set*, so that the credentials can be shared across both workspaces.

* Navigate to the home page of the Terraform Cloud console, then go to *Settings > Variable Sets > Create Variable Set*
* Name the variable set whatever you like, say “GCP Credentials”
* Select the 2 workspaces to apply this Variable Set to (the manage and provision workspaces)

Do the same process as before  when adding a Variable to the provision workspace:
* Add an environment variable and use the stripped json file (no newlines) that you saved from before as the value 
* Enter “GOOGLE_CREDENTIALS” as the key
* Mark the variable as sensitive
* Then click *Create variable set*

This variable set should allow both workspaces to access the GCP credentials and therefore be able to connect to GCP.

By now, the manage workspace should be able to access the state generate by the provision workspace as well as access the same GCP credentials, so plans and applies should be able to run from there.

### Finally, let’s actually deploy Jenkins itself to the cluster.

* First, create a values.yaml file in the root directory of your project.

* Go ahead and copy the code from here: https://github.com/calvinliphc/terraform-jenkins/blob/main/values.yaml

* Then, create a new terraform configuration file called `jenkins.tf` in the manage directory of your project.

* Use the code from this file: https://github.com/calvinliphc/terraform-jenkins/blob/main/GKE/manage/jenkins.tf

After applying this new configuration, the helm chart for Jenkins should be applied to the Kubernetes cluster and the Jenkins web interface should be exposed at <kubernetes_cluster_host>:8080

Congrats! Say hi to Jenkins!




