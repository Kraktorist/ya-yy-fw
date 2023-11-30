terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    endpoint="storage.yandexcloud.net"
    region="ru-central1"
    workspace_key_prefix="tfstates"
    key="cloud.tfstate"
    skip_region_validation=true
    skip_credentials_validation=true

  }
}