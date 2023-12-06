#!/usr/bin/env bash
ACTION=$1
ENV=$2

if [ -z ${ENV} ]; then
  echo "ENV is not defined"
  exit 1
fi

if ! [[ ${ACTION} =~ ^(apply|destroy)$ ]]; then
  echo "ACTION is not valid. Should be 'apply' or 'destroy'"
  exit 1
fi

terraform_dir=terraform2

source ./scripts/init.sh
set -euo pipefail
export ENV
export TF_VAR_env_folder=$(pwd)/envs/${ENV}
terraform -chdir=terraform2 init -backend-config="bucket=${S3_TF_STATE}" -reconfigure
terraform -chdir=terraform2 workspace select ${ENV} || terraform -chdir=terraform2 workspace new ${ENV}
terraform -chdir=terraform2 ${ACTION}

# if [ "${ACTION}" = "apply" ]; then
#     eval $(terraform -chdir=terraform2 output -raw ANSIBLE_SSH_COMMON_ARGS || true)
#     ansible-playbook -i envs/${ENV}/inventory.yaml ansible/playbook.yml
#     terraform -chdir=terraform2 output
# fi