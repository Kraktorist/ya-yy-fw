output public_ips {
  value       = {
    for key, entry in yandex_compute_instance.instance: 
      key => entry.network_interface[0].nat_ip_address if entry.network_interface[0].nat_ip_address != ""
  }
}

output ANSIBLE_SSH_COMMON_ARGS {
  value       = try("export ANSIBLE_SSH_COMMON_ARGS='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -q ${values(local.ansible_inventory["bastion"].hosts)[0].ansible_user}@${values(local.ansible_inventory["bastion"].hosts)[0].nat_address} -p 22\"'",null)
  description = "hint for ssh proxy variable ANSIBLE_SSH_COMMON_ARGS"
}


output lb_lb_endpoints {
  value = {
    for key, entry in yandex_lb_network_load_balancer.lb:
      key => "${tolist(tolist(entry.listener)[0].external_address_spec)[0].address}:${tolist(entry.listener)[0].target_port}"
  }
}