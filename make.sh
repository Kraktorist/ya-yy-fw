#!/usr/bin/env bash
ACTION=$1
ENV=$2

if [ -z ${ENV} ]; then
  echo "ENV is not defined"
  exit 1
fi

if [ -z ${ACTION} ]; then
  echo "ACTION is not defined"
  exit 1
fi


source ./scripts/init.sh
set -euo pipefail
export ENV
export TF_VAR_env_folder=$(pwd)/envs/${ENV}
terraform -chdir=terraform init -backend-config="bucket=${S3_TF_STATE}" -reconfigure
terraform -chdir=terraform workspace select ${ENV} || terraform -chdir=terraform workspace new ${ENV}
terraform -chdir=terraform ${ACTION}

if [ "${ACTION}" = "apply" ]; then
    eval $(terraform -chdir=terraform output -raw ANSIBLE_SSH_COMMON_ARGS || true)
    ansible-playbook -i envs/${ENV}/inventory.yaml ansible/playbook.yml
    terraform -chdir=terraform output
fi