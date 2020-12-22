# Terraform Deployment
This repository is the "walk" version of learning how to run terraform deployments on Google Cloud. This script will help move towards the best practice of using a service account with least privilege for the deployment and Google Storage to store the state remotely. The end goal will be running infrastructure deployments in a pipeline, but this script will give the user the knowledge of how it works. Then they'll know how to fix the pipeline when terraform "weirdness" occurs. Also, pipelines usually come back to bash script and now you have one.

## Software Requirements

### Terraform plugins
- [Terraform](https://www.terraform.io/downloads.html) 0.12.x
- [terraform-provider-google](https://github.com/terraform-providers terraform-provider-google) plugin v3.44.0
- [terraform-provider-google-beta](https://github.com/terraform-providers/terraform-provider-google-beta) plugin v3.44.0

## Usage
The script depends on the following prerequisites which has integration checks in case they are missed.

### Chicken & Egg IAM Service account 
 - [Create a service account to create service accounts](https://github.com/jasonbisson/gcp_service_accounts/blob/master/create_service_account.sh)

- Assign Security Admin IAM role via console or gcloud at the GCP Organization level

### Service Account for Terraform deployment

- [Create a service account with unique name in service account project](https://github.com/jasonbisson/gcp_service_accounts/blob/master/create_service_account.sh)

- Update Terraform variables to apply IAM roles to service account 
```
cd  ~
git clone https://github.com/terraform-google-modules/terraform-google-iam.git
mkdir terraform-service-account-<my unique deployment>
cp terraform.tfvars.template ../terraform-service-account-<my unique deployment>/terraform.tfvars
#Update required IAM roles in terraform.tfvars 
```

### Required Google Cloud variables & resources for workflow
  - Google Cloud Project ID is configured
  ```
    gcloud config set project PROJECT_ID 
  ```
  - Google Storage Bucket to store Terraform state is created under the GCP project with the name $project_id-state
  ```
    gsutil mb gs://<Bucket for Terraform state files>
  ```
### Required Terraform variables for workflow

  - Terraform parent module location
  ```
     export terraform_module=$HOME/terraform-google-<suffix of repo>/examples/<name of module> 
  ```
  - Terraform variable file with custom values
  ```
      export terraform_module_config=$HOME/path_to_tfvar
  ```
  - Terraform State file
  ```
      export terraform_deployment_name=my_unique_terraform_deployment_name
  ```

### Terraform deployment command

  - Deploy command with plan first, then apply, and for fun destroy.
  ```
  terraform_workflow_token.sh --terraform_service_account <shortname_terraform_deployment_service_account> --terraform_action <plan,apply,destroy>
  ```

### Service account key script

- This is a legacy script I used when I thought service account keys was the only option until read [Stop Downloading Service account keys](https://medium.com/@jryancanty/stop-downloading-google-cloud-service-account-keys-1811d44a97d9)

