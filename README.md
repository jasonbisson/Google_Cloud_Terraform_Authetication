# Terraform Deployment
This repository has crawl, walk, run and fly versions of learning how to run terraform deployments on Google Cloud. The first section focuses on moving towards the best practice of using a service account with the least privilege for the deployment and Google Storage as the Terraform backend. The end goal will be running infrastructure deployments in a pipeline, but with this guide, you'll build the muscle of knowing how it works before handing the keys to the robots. Then they'll learn how to fix the pipeline when Terraform "weirdness" occurs.

## Software Requirements

### Terraform plugins
- [Terraform](https://www.terraform.io/downloads.html) 
- [terraform-provider-google](https://github.com/terraform-providers/terraform-provider-google) 
- [terraform-provider-google-beta](https://github.com/terraform-providers/terraform-provider-google-beta) 

## Google Service Account Management 

### IAM Policy service account

 - [Create a service account for IAM Policy updates](https://github.com/jasonbisson/gcp_service_accounts/blob/master/create_service_account.sh)

- Assign Security Admin IAM role via console or gcloud at the GCP Organization level.

### Infrastructure deployment service account

- [Create a service account with unique name in service account project](https://github.com/jasonbisson/gcp_service_accounts/blob/master/create_service_account.sh)

- Update IAM permissions of service account via console, gcloud, or [Terraform](https://github.com/terraform-google-modules/terraform-google-iam.git). 

## Terraform Backend Management

### Create Google Storage bucket to store Terraform state
  - Google Cloud Project ID is configured
  ```
    gcloud config set project PROJECT_ID 
  ```
  - Create Google storage bucket
  ```
    gsutil mb gs://<Bucket for Terraform state files>
  ```
  - Configure versioning for Google storage bucket
  ```
  gsutil versioning set on gs://<Bucket for Terraform state files>
  ```

## Infrastructure deployment options

### Infrastructure deployment with Terraform binary (Crawl)
```
terraform init -backend=true -backend-config="bucket=<GCS Bucket for Terraform state files>" -backend-config="prefix=<unique_terraform_deployment_name>"
terraform plan
terraform apply
terraform destroy
```

### Infrastructure deployment with wrapper script (Walk)

  - Export Terraform parent module variable
  ```
     export terraform_module=$HOME/terraform-google-<suffix of repo>/examples/<name of module> 
  ```
  - Export Terraform custom variable file 
  ```
      export terraform_module_config=$HOME/path_to_tfvar
  ```
  - Export Terraform state file name
  ```
      export terraform_deployment_name=unique_terraform_deployment_name
  ```
  - Run script with plan first, then apply, and destroy.
  ```
  terraform_workflow_token.sh --terraform_service_account <shortname_terraform_deployment_service_account> --terraform_action <plan,apply,destroy>
  ```

### Infrastructure deployment with Cloud Build (Run)

  - Run Terraform plan
  ```
  gcloud builds submit . --config=cloudbuild-plan.yaml --substitutions _STATEBUCKET='<GCS Bucket for Terraform state files>',_STATEFOLDER='<Unique name for deployment>'
  ```

  - Run Terraform apply
  ```
  gcloud builds submit . --config=cloudbuild-apply.yaml --substitutions _STATEBUCKET='<GCS Bucket for Terraform state files>',_STATEFOLDER='<Unique name for deployment>'
  ```

  - Run Terraform destroy
  ```
  gcloud builds submit . --config=cloudbuild-apply.yaml --substitutions _STATEBUCKET='<GCS Bucket for Terraform state files>',_STATEFOLDER='<Unique name for deployment>'
  ```

### [Infrastructure deployment with Github Cloud Build App](https://cloud.google.com/solutions/managing-infrastructure-as-code) (Fly)







