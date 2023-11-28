output public_ips {
  value       = {
    for key, entry in yandex_compute_instance.instance: 
      key => entry.network_interface[0].nat_ip_address if entry.network_interface[0].nat_ip_address != ""
  }
}
