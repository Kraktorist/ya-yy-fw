locals {
  config = yamldecode(file("config.yaml"))
}

provider "yandex" {
  folder_id = local.config.folder_id
}

resource "yandex_vpc_network" "network" {
  name = local.config.network.name
}

resource "yandex_vpc_subnet" "network" {
  for_each = local.config.network.subnets
  network_id     = yandex_vpc_network.network.id
  name           = each.key
  v4_cidr_blocks = each.value.v4_cidr_blocks
  zone = each.value.zone
}

resource "yandex_container_registry" "registry" {
  name = try(local.config.registry.name, "registry")

  labels = try(local.config.registry.labels, {})

}

data "yandex_compute_image" "coi" {
  family = try(local.config.instance_group.image_family, "container-optimized-image")
}

resource "yandex_iam_service_account" "ig-account" {
  name     = local.config.instance_group.service_account
}

resource "yandex_compute_instance_group" "group" {
  name                = local.config.instance_group.name
  service_account_id  = yandex_iam_service_account.ig-account.id
  instance_template {
    platform_id = "standard-v2"
    resources {
      cores         = local.config.instance_group.resources.cores
      memory        = local.config.instance_group.resources.memory
      core_fraction = try(local.config.instance_group.resources.core_fraction, 5)
    }
    boot_disk {
      initialize_params {
        type = "network-hdd"
        size = local.config.instance_group.resources.disk_size
        image_id = data.yandex_compute_image.coi.id
      }
    }
    network_interface {
      subnet_ids = [ for v in yandex_vpc_subnet.network: v.id if local.config.instance_group.network.subnet == v.name ]
      nat = local.config.instance_group.network.nat
    }
    metadata = {
      foo      = "bar"
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = local.config.instance_group.node_count
    }
  }

  allocation_policy {
    zones = local.config.instance_group.allocation_policy
  }

  deploy_policy {
    max_unavailable = local.config.instance_group.deploy_policy.max_unavailable
    max_expansion   = local.config.instance_group.deploy_policy.max_expansion
  }
}

