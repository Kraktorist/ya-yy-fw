#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

function red {
    printf "${RED}$@${NC}\n"
}

function green {
    printf "${GREEN}$@${NC}\n"
}

function yellow {
    printf "${YELLOW}$@${NC}\n"
}

for i in "$@"; do
  case $i in
    -f=*|--folder-id=*)
      FOLDER_ID="${i#*=}"
      shift
      ;;
    -s=*|--service-account=*)
      SERVICE_ACCOUNT="${i#*=}"
      shift
      ;;
    -r=*|--role=*)
      ROLE="${i#*=}"
      shift
      ;;
    -b=*|--bucket=*)
      S3_TF_STATE="${i#*=}"
      shift
      ;;
    -*|--*)
      echo $(yellow "Unknown option $i")
      exit 1
      ;;
    *)
      ;;
  esac
done

if [ -z ${FOLDER} ]; then
  FOLDER=qamo
  echo $(yellow "WARNING! Parameter --folder is not set. Default value --folder=${FOLDER} will be used.")
fi
if [ -z ${SERVICE_ACCOUNT} ]; then
  SERVICE_ACCOUNT=${FOLDER}-terraform
  echo $(yellow "WARNING! Parameter --service-account is not set. Default value --service-account=${SERVICE_ACCOUNT} will be used.")
fi
if [ -z ${ROLE} ]; then
  ROLE=admin
  echo $(yellow "WARNING! Parameter --role is not set. Default value --role=${ROLE} will be used.")
fi
if [ -z ${S3_TF_STATE} ]; then
  S3_TF_STATE=${FOLDER}-tfstates
  echo $(yellow "WARNING! Parameter --bucket is not set. Default value --bucket=${S3_TF_STATE} will be used.")
fi

KEY_FILE=.key.json

echo $(yellow "Creating Service Account ${SERVICE_ACCOUNT}")
yc iam service-account create ${SERVICE_ACCOUNT} --folder-name ${FOLDER}

echo $(yellow "Assigning requested role ${ROLE}")
yc resource-manager folder add-access-binding ${FOLDER} \
  --service-account-name ${SERVICE_ACCOUNT} \
  --role ${ROLE} \
  --folder-name ${FOLDER}

echo $(yellow "Creating IAM key for the service account")
yc iam key create \
  --service-account-name ${SERVICE_ACCOUNT} \
  --folder-name ${FOLDER} \
  --output ${KEY_FILE}

echo $(yellow "Creating IAM access-key for access to S3")
secret=$(yc iam access-key create \
  --service-account-name ${SERVICE_ACCOUNT} \
  --folder-name ${FOLDER} \
  --format json)

echo $(yellow "Creating S3 bucket ${S3_TF_STATE}")
export AWS_ACCESS_KEY_ID=$(echo ${secret} | jq -r .access_key.key_id)
export AWS_SECRET_ACCESS_KEY=$(echo ${secret} | jq -r .secret)
export AWS_REGION=ru-central1
aws --endpoint-url=https://storage.yandexcloud.net s3 mb s3://${S3_TF_STATE}

# echo $(yellow "EXPORTED VALUES:")
# echo "export YC_ZONE=ru-central1-a"
# echo "export YC_CLOUD_ID=$(yc config get cloud-id)"
# echo "export YC_FOLDER_ID=$(yc config get folder-id)"
# echo "export YC_SERVICE_ACCOUNT_KEY_FILE=${KEY_FILE}"
# echo "export YC_STORAGE_ACCESS_KEY=${AWS_ACCESS_KEY_ID}"
# echo "export YC_STORAGE_SECRET_KEY=${AWS_SECRET_ACCESS_KEY}"
# echo "export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
# echo "export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
# echo "export S3_TF_STATE=${S3_TF_STATE}"

export YC_ZONE=ru-central1-a
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
export YC_SERVICE_ACCOUNT_KEY_FILE=${KEY_FILE}
export YC_STORAGE_ACCESS_KEY=${AWS_ACCESS_KEY_ID}
export YC_STORAGE_SECRET_KEY=${AWS_SECRET_ACCESS_KEY}
export S3_TF_STATE=${S3_TF_STATE}