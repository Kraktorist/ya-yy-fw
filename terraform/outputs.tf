output public_ips {
  value       = {
    for key, entry in yandex_compute_instance.instance: 
      key => entry.network_interface[0].nat_ip_address if entry.network_interface[0].nat_ip_address != ""
  }
}

output ANSIBLE_SSH_COMMON_ARGS {
  value       = try("export ANSIBLE_SSH_COMMON_ARGS='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -q ${local.ansible_inventory["bastion"].hosts["bastion"].ansible_user}@${local.ansible_inventory["bastion"].hosts["bastion"].nat_address} -p 22\"'",null)
  description = "hint for ssh proxy variable ANSIBLE_SSH_COMMON_ARGS"
}
