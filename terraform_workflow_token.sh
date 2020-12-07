#!/bin/bash
set -x
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


[[ "$#" -ne 4 ]] && { echo "Usage : `basename "$0"` --terraform_service_account <shortname_terraform_service_account> --terraform_action <plan,apply,destroy>"; exit 1; }
[[ "$1" = "--terraform_service_account" ]] &&  export terraform_service_account=$2
[[ "$3" = "--terraform_action" ]] &&  export action=$4

export project_id=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
export statebucket=$project_id-state
export bucket_exists=$(gsutil ls -b gs://$project_id-state)

function check_gcp_variables () {
    if [  -z "$project_id" ]; then
        printf "ERROR: GCP PROJECT_ID is not set.\n\n"
        printf "To view the current PROJECT_ID config: gcloud config list project \n\n"
        printf "To view available projects: gcloud projects list \n\n"
        printf "To update project config: gcloud config set project PROJECT_ID \n\n"
        exit
    fi
    
    if [  -z "$bucket_exists" ]; then
        printf "Error: GCS Bucket to save Terraform state is not set.\n\n"
        printf "Run to create the bucket gsutil mb gs://${statebucket}"
        printf "Also, confirm this project is correct to store Terraform state: $project_id"
        exit
    fi
    
}

function check_terraform_variables () {
    if [  -z "$terraform_module" ]; then
        printf "ERROR: terraform-google-module is not set. Set the module in shell\n\n"
        printf "Run export terraform_module=$HOME/terraform-google-<suffix of repo>/examples/<name of module> \n\n"
        exit
    fi
    
    if [  -z "$terraform_module_config" ]; then
        printf "ERROR: The path to the Terraform variable file is not defined.\n\n"
        printf "Run export terraform_module_config=$HOME/path_to_tfvar file \n\n"
        exit
    fi
    
    if [  -z "$terraform_deployment_name" ]; then
        printf "ERROR: The unique Terraform deployment name is not set which is required to save a unique Terraform state file.\n\n"
        printf "Run export terraform_deployment_name=my_unique_terraform_deployment_name.$$ \n\n"
        exit
    fi
}


function impersonate () {
    export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud --impersonate-service-account=${terraform_service_account}@${project_id}.iam.gserviceaccount.com auth print-access-token 2>/dev/null)
    if [  -z "$GOOGLE_OAUTH_ACCESS_TOKEN" ]; then
        printf "ERROR: Access token not available for session.\n\n"
        printf "Run gcloud auth print-access-token to diagnosis the root cause \n\n"
        exit
    fi
}

function run_terraform () {
    cd $terraform_module
    terraform init -backend=true -backend-config="bucket=${statebucket}" -backend-config="prefix=${terraform_deployment_name}"
    terraform ${action} -var-file=${terraform_module_config}
}

function clear_impersonate () {
    gcloud config unset auth/impersonate_service_account
}

check_gcp_variables
check_terraform_variables
impersonate
run_terraform
clear_impersonate
