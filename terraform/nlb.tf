resource "yandex_lb_network_load_balancer" "lb" {
  for_each           = try(local.config.instance_groups, {})
  name = "${each.key}-load-balancer"

  labels = {
    group = each.value.ansible_groups[0]
  }

  listener {
    name = each.key
    port = each.value.lb.port
    target_port = try(each.value.lb.target_port, each.value.lb.port)
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.group[each.key].load_balancer[0].target_group_id
    healthcheck {
      name = "http"
      unhealthy_threshold = try(each.value.lb.healthcheck.unhealthy_threshold,1)
      interval = try(each.value.lb.healthcheck.interval,1)
      http_options {
        port = each.value.lb.healthcheck.port
        path = each.value.lb.healthcheck.path
      }
    }
  }
}