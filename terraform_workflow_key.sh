#!/bin/bash
#set -x
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


[[ "$#" -ne 4 ]] && { echo "Usage : `basename "$0"` --environment <unique_environment_flag> --terraform-action <plan,apply,destroy>"; exit 1; }
[[ "$1" = "--environment" ]] &&  export environment=$2
[[ "$3" = "--terraform-action" ]] &&  export action=$4

export parent_directory=$(pwd)
export project_id=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
export keybucket=$project_id-userkeys
export statebucket=$project_id-state
export keyfile=$(gsutil ls -l gs://${keybucket}/${environment}*json.encrypted | sort -k2n | tail -n1 | awk 'END {$1=$2=""; sub(/^[ \t]+/, ""); print }')
export cryptokey=$(gcloud kms keys describe $environment --keyring $environment --location global --format="value(name)")
export token=$(gcloud auth application-default print-access-token 2>/dev/null)

function check_variables () {
    if [  -z "$project_id" ]; then
        printf "ERROR: GCP PROJECT_ID is not set.\n\n"
        printf "To view the current PROJECT_ID config: gcloud config list project \n\n"
        printf "To view available projects: gcloud projects list \n\n"
        printf "To update project config: gcloud config set project PROJECT_ID \n\n"
        exit
    fi
    
    if [  -z "$token" ]; then
        printf "ERROR: Access token not available for application-default session.\n\n"
        printf "Run gcloud auth application-default print-access-token to diagnosis the root cause \n\n"
        exit
    fi
    
    if [  -z "$cryptokey" ]; then
        printf "ERROR: Crypto Key used to decrypt the Service account key is not set or doesn't exist.\n\n"
        exit
    fi
    
    if [  -z "$keyfile" ]; then
        printf "ERROR: Service account key is not set or doesn't exist in $keybucket.\n\n"
        exit
    fi
    
    if [  -z "$statebucket" ]; then
        printf "Error: GCS Bucket to save Terraform state is not set.\n\n"
        exit
    fi
    
    if [  -z "$keybucket" ]; then
        printf "ERROR: GCS Bucket to store user managed service account keys is not set.\n\n"
        exit
    fi
    
    if [  -z "$module" ]; then
        printf "ERROR: terraform-google-module is not set. Set the module in shell\n\n"
        printf "Run export module=$HOME/terraform-google-<suffix of repo>/examples/<name of module> \n\n"
        exit
    fi
    
    if [  -z "$module_config" ]; then
        printf "ERROR: The path to the Terraform variable file is not defined.\n\n"
        printf "Run export module_config=$HOME/path_to_tfvar file \n\n"
        exit
    fi
}

function check_bucket () {
    exists=$(gsutil ls -b gs://$statebucket)
    if [  -z "$exists" ]; then
        gsutil mb gs://${statebucket}
    fi
}

function decrypt_file () {
    curl -s "https://cloudkms.googleapis.com/v1/projects/$project_id/locations/global/keyRings/$environment/cryptoKeys/$environment:decrypt" \
    -d "{\"ciphertext\":\"$(gsutil cat $keyfile)\"}" \
    -H "Authorization:Bearer $token"\
    -H "Content-Type:application/json" \
    | jq .plaintext -r | base64 -D > $environment.json
    export GOOGLE_APPLICATION_CREDENTIALS=$PWD/$(ls -t ${environment}*.json |head -1)
}

function run_terraform () {
    cd $module
    terraform init -backend=true -backend-config="bucket=${statebucket}" -backend-config="prefix=${environment}"
    terraform ${action} -var-file=${module_config} 
}

function remove_file () {
    rm -f ${parent_directory}/${environment}*.json*
}

check_variables
check_bucket
decrypt_file
run_terraform
remove_file
