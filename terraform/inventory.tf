locals {
  ansible_groups_for_instances = distinct(flatten(values(local.config.instances)[*].ansible_groups))
  ansible_inventory_for_instances = {
    for group in local.ansible_groups_for_instances :
    group => {
      hosts = { for key, entry in local.config.instances :
        key => { 
          ansible_host = yandex_compute_instance.instance[key].fqdn
          nat_address = try(yandex_compute_instance.instance[key].network_interface[0].nat_ip_address, null)
          ansible_user = entry.metadata.ssh-keys.username
        }
      if contains(entry.ansible_groups, group) }
    }
  }

  ansible_groups_for_group_instances = distinct(flatten(values(local.config.instance_groups)[*].ansible_groups))
  hosts = merge([
    for k1, v1 in yandex_compute_instance_group.group :
    {
      for v2 in v1.instances :
      v2.name => {
        group          = k1
        ansible_host             = v2.fqdn
        nat_address = try(v2.network_interface[0].nat_ip_address,null)
        ansible_user = local.config.instance_groups[k1].metadata.ssh-keys.username
        ansible_groups = local.config.instance_groups[k1].ansible_groups
      }
    }
  ]...)

  ansible_inventory_for_instance_groups = {
    for group in local.ansible_groups_for_group_instances :
    group => {
      hosts = {
        for key, entry in local.hosts :
        key => { 
          ansible_host = entry.ansible_host 
          ansible_user = entry.ansible_user  
        }

        if contains(entry.ansible_groups, group)
      }
    }
  }

  ansible_inventory = merge(local.ansible_inventory_for_instance_groups, local.ansible_inventory_for_instances)

}

resource "local_file" "ansible_inventory" {
  filename = try(local.config.inventory_file,"inventory.yaml")
  content  = yamlencode(local.ansible_inventory)
}
