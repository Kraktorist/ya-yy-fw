# TODO define some defaults for locals
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
  for_each = local.config.registries
  name = each.key

  labels = try(each.value.labels, {})

}

data "yandex_compute_image" "coi" {
  for_each = try(local.config.instance_groups, {})
  family = try(each.value.image_family, "container-optimized-image")
}

resource "yandex_iam_service_account" "service-account" {
  for_each = local.config.service_accounts
  name     = each.key
}

locals {
  permissions = flatten([
    for name,service_account in local.config.service_accounts: [
      for entry in service_account.roles : {
        sa_name       = name
        role = entry
      }
    ]
  ])
}

resource "yandex_resourcemanager_folder_iam_member" "ig-roles" {
  for_each = {
      for entry in local.permissions: "${entry.sa_name}-${entry.role}" => entry
    }
  folder_id = local.config.folder_id
  member    = "serviceAccount:${yandex_iam_service_account.service-account[each.value.sa_name].id}"
  role      = each.value.role
}

locals {
  metadata = {
    for ig_name, instance_group in merge(try(local.config.instance_groups, {}), try(local.config.instances, {})):
      ig_name => {
        docker-compose = coalescelist([for key, entry in instance_group.metadata: file(entry.file) if key == "docker-compose"], [null])[0]
        ssh-keys = coalescelist([for key, entry in instance_group.metadata: "${entry.username}:${file(entry.file)}" if key == "ssh-keys"], [null])[0]
      }
  }
}


resource "yandex_compute_instance_group" "group" {
  for_each = try(local.config.instance_groups, {})
  name                = each.key
  service_account_id = [ for v in yandex_iam_service_account.service-account: v.id if each.value.service_account == v.name ][0]
  instance_template {
    platform_id = "standard-v2"
    resources {
      cores         = each.value.resources.cores
      memory        = each.value.resources.memory
      core_fraction = try(each.value.resources.core_fraction, 5)
    }
    boot_disk {
      initialize_params {
        type = try(each.value.resources.disk_type, "network-hdd")
        size = each.value.resources.disk_size
        image_id = data.yandex_compute_image.coi[each.key].id
      }
    }
    network_interface {
      subnet_ids = [ for v in yandex_vpc_subnet.network: v.id if each.value.network.subnet == v.name ]
      nat = try(each.value.network.nat, false)
    }
    
    metadata = local.metadata[each.key]

    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = each.value.node_count
    }
  }

  allocation_policy {
    zones = each.value.allocation_policy
  }

  deploy_policy {
    max_unavailable = each.value.deploy_policy.max_unavailable
    max_expansion   = each.value.deploy_policy.max_expansion
  }
  depends_on = [
    yandex_iam_service_account.service-account,
    yandex_resourcemanager_folder_iam_member.ig-roles
  ]
}

data "yandex_compute_image" "image" {
  for_each = local.config.instances
  family = try(each.value.image_family, "container-optimized-image")
}

resource "yandex_compute_instance" "instance" {
  for_each = local.config.instances
  name        = each.key
  platform_id = "standard-v2"

    resources {
      cores         = each.value.resources.cores
      memory        = each.value.resources.memory
      core_fraction = try(each.value.resources.core_fraction, 5)
    }

    boot_disk {
      initialize_params {
        type = try(each.value.resources.disk_type, "network-hdd")
        size = each.value.resources.disk_size
        image_id = data.yandex_compute_image.image[each.key].id
      }
    }

    network_interface {
      subnet_id = [ for v in yandex_vpc_subnet.network: v.id if each.value.network.subnet == v.name ][0]
      nat = try(each.value.network.nat, false)
    }

  metadata = local.metadata[each.key]
}