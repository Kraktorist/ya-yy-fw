locals {
  ansible_inventory_for_instances = {
    for group in distinct(flatten(values(local.config.instances)[*].ansible_groups)):
        group => {
            hosts = {for key, entry in local.config.instances: 
              key => {ansible_host = yandex_compute_instance.instance[key].network_interface[0].ip_address}
              if contains(entry.ansible_groups, group ) }
        }
  }
#   ansible_inventory_for_instance_groups = {
#     for group in distinct(flatten(values(local.config.instance_groups)[*].ansible_groups)):
#         group => {
#             hosts = {for key, entry in local.config.instance_groups: 
#               yandex_compute_instance_group.group[key].instances[0].name => {ansible_host = yandex_compute_instance_group.group[key].instances[0].network_interface[0].ip_address}
#               if contains(entry.ansible_groups, group ) }
#         }
#   }
  ansible_inventory_for_instance_groups = {
    for group in distinct(flatten(values(local.config.instance_groups)[*].ansible_groups)):
        group => {
            hosts = {
              for key, entry in local.config.instance_groups: "xxx" => {
                for entry in yandex_compute_instance_group.group[key].instances:
                  entry.fqdn => {ansible_host = entry.network_interface[0].ip_address}
              }
              if contains(entry.ansible_groups, group ) 
            }
        }
  }
  ansible_inventory = merge(local.ansible_inventory_for_instance_groups, local.ansible_inventory_for_instances)
}

output ansible_inventory {
  value       = local.ansible_inventory
}

resource "local_file" "ansible_inventory" {
    filename = "xxx.yaml"
    content     = yamlencode(local.ansible_inventory)
}

# output test {
#   value       = yandex_compute_instance_group.group["bingo"].instances[0].network_interface[0].ip_address
# }
