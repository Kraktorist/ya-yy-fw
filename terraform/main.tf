# TODO define some defaults for locals
# TODO split configuration to modules
locals {
  config = yamldecode(file("${var.env_folder}/${var.env_file}"))
}

provider "yandex" {
  folder_id = local.config.folder_id
}

resource "yandex_vpc_network" "network" {
  name = local.config.network.name
}

resource "yandex_vpc_gateway" "egress-gateway" {
  name = "egress-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = "${yandex_vpc_gateway.egress-gateway.id}"
  }
}

resource "yandex_vpc_subnet" "network" {
  for_each       = local.config.network.subnets
  network_id     = yandex_vpc_network.network.id
  name           = each.key
  v4_cidr_blocks = each.value.v4_cidr_blocks
  zone           = each.value.zone
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_container_registry" "registry" {
  for_each = try(local.config.registries,{})
  name     = each.key

  labels = try(each.value.labels, {})

}

data "yandex_compute_image" "coi" {
  for_each = try(local.config.instance_groups, {})
  family   = try(each.value.image_family, "container-optimized-image")
}

resource "yandex_iam_service_account" "service-account" {
  for_each = local.config.service_accounts
  name     = each.key
}

locals {
  permissions = flatten([
    for name, service_account in local.config.service_accounts : [
      for entry in service_account.roles : {
        sa_name = name
        role    = entry
      }
    ]
  ])
}

resource "yandex_resourcemanager_folder_iam_member" "ig-roles" {
  for_each = {
    for entry in local.permissions : "${entry.sa_name}-${entry.role}" => entry
  }
  folder_id = local.config.folder_id
  member    = "serviceAccount:${yandex_iam_service_account.service-account[each.value.sa_name].id}"
  role      = each.value.role
}

locals {
  metadata = {
    for ig_name, instance_group in merge(try(local.config.instance_groups, {}), try(local.config.instances, {})) :
    ig_name => {
      docker-compose = coalescelist([for key, entry in instance_group.metadata : file(entry.file) if key == "docker-compose"], [null])[0]
      ssh-keys       = coalescelist([for key, entry in instance_group.metadata : "${entry.username}:${file(entry.file)}" if key == "ssh-keys"], [null])[0]
    }
  }
}


resource "yandex_compute_instance_group" "group" {
  for_each           = try(local.config.instance_groups, {})
  name               = each.key
  service_account_id = [for v in yandex_iam_service_account.service-account : v.id if each.value.service_account == v.name][0]
  instance_template {
    platform_id = "standard-v2"
    resources {
      cores         = each.value.resources.cores
      memory        = each.value.resources.memory
      core_fraction = try(each.value.resources.core_fraction, 5)
    }
    boot_disk {
      initialize_params {
        type     = try(each.value.resources.disk_type, "network-hdd")
        size     = each.value.resources.disk_size
        image_id = data.yandex_compute_image.coi[each.key].id
      }
    }
    network_interface {
      subnet_ids = [for v in yandex_vpc_subnet.network : v.id if each.value.network.subnet == v.name]
      nat        = try(each.value.network.nat, false)
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
  family   = try(each.value.image_family, "container-optimized-image")
}

resource "yandex_compute_instance" "instance" {
  for_each    = local.config.instances
  name        = each.key
  platform_id = "standard-v2"
  zone = [for v in yandex_vpc_subnet.network : v.zone if each.value.network.subnet == v.name][0]

  resources {
    cores         = each.value.resources.cores
    memory        = each.value.resources.memory
    core_fraction = try(each.value.resources.core_fraction, 5)
  }

  boot_disk {
    initialize_params {
      type     = try(each.value.resources.disk_type, "network-hdd")
      size     = each.value.resources.disk_size
      image_id = data.yandex_compute_image.image[each.key].id
    }
  }

  dynamic "secondary_disk" {
    for_each = contains(keys(each.value.resources), "secondary_disk_size") ? [1] : []
    content {
      disk_id = yandex_compute_disk.secondary_disk[each.key].id
      auto_delete = true
      device_name = "vdb"
    }
  }

  network_interface {
    subnet_id = [for v in yandex_vpc_subnet.network : v.id if each.value.network.subnet == v.name][0]
    nat       = try(each.value.network.nat, false)
  }

  metadata = local.metadata[each.key]
}

resource "yandex_compute_disk" "secondary_disk" {
  for_each = { for k, v in local.config.instances : k => v if contains(keys(v.resources), "secondary_disk_size")  }
  name     = "${each.key}-secondary-disk"
  type     = "network-ssd"
  size = each.value.resources.secondary_disk_size
  zone = [for v in yandex_vpc_subnet.network : v.zone if each.value.network.subnet == v.name][0]
}