# Terraform Deployment
This repository is the "walk" version of learning how to run terraform deployments on Google Cloud. This script will help move towards the best practice of using a service account with least privilege for the deployment and Google Storage to store the state remotely. The end goal will be running infrastructure deployments in a pipeline, but this script will give the user the knowledge of how it works. Then they'll know how to fix the pipeline when terraform "weirdness" occurs. Also, pipelines usually come back to bash script and now you have one.

## Software Requirements

### Terraform plugins
- [Terraform](https://www.terraform.io/downloads.html) 0.12.x
- [terraform-provider-google](https://github.com/terraform-providers terraform-provider-google) plugin v3.44.0
- [terraform-provider-google-beta](https://github.com/terraform-providers/terraform-provider-google-beta) plugin v3.44.0

## Service Accounts Management 

### Service Account for IAM policy

 - [Create a service account for IAM Policy updates](https://github.com/jasonbisson/gcp_service_accounts/blob/master/create_service_account.sh)

- Assign Security Admin IAM role via console or gcloud at the GCP Organization level.

### Service Account for Infrastructure deployment

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
```
```
terraform plan
```
```
terraform apply
```
```
terraform destroy
```

### Infrastructure deployment with wrapper script (Walk)

#### Export required variables

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
      export terraform_deployment_name=unique_terraform_deployment_name
  ```

  - Deploy command with plan first, then apply, and for fun destroy.
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

### [Infrastructure deployment with Github Cloud Build App](https://cloud.google.com/solutions/managing-infrastructure-as-code)







