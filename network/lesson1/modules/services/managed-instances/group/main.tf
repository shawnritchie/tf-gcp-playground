terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
}

resource "google_compute_target_pool" "pool" {
  name = format("pool-%s", var.group_name)
  project = var.project_id
  region = var.region
  session_affinity = "NONE"
}

resource "google_compute_region_instance_group_manager" "group" {
  name = format("grp-%s", var.group_name)
  base_instance_name = format("inst-%s", var.group_name)
  project = var.project_id
  region = var.region
  distribution_policy_zones = var.zones
  distribution_policy_target_shape = "EVEN"

  dynamic "named_port" {
    for_each = var.named_port

    content {
      name = named_port.key
      port = named_port.value
    }
  }

  version {
    instance_template = var.template_id
  }

  target_pools = [google_compute_target_pool.pool.id]

  dynamic "auto_healing_policies" {
    for_each = toset(var.health_checks)

    content {
      health_check = auto_healing_policies.value
      initial_delay_sec = 300
    }
  }

  update_policy {
    minimal_action = "REPLACE"
    type = "PROACTIVE"
    replacement_method = "SUBSTITUTE"
    max_unavailable_fixed = 2
  }

  wait_for_instances = false

  depends_on = [google_compute_target_pool.pool]
}

resource "google_compute_region_autoscaler" "autoscaler" {
  project = var.project_id
  name = format("autoscaler-%s", var.group_name)
  region = var.region
  target = google_compute_region_instance_group_manager.group.id

  autoscaling_policy {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    cooldown_period = 60

    dynamic "cpu_utilization" {
      for_each = var.cpu_utilisation == null ? {} : {"cpu_utilisation": var.cpu_utilisation}

      content {
        target  = cpu_utilization.value
        predictive_method = "OPTIMIZE_AVAILABILITY"
      }
    }

    dynamic "load_balancing_utilization" {
      for_each = var.load_balancing_utilisation == null ? {} : {"load_balancing_utilisation": var.load_balancing_utilisation}

      content {
        target = load_balancing_utilization.value
      }
    }

    dynamic "metric" {
      for_each = var.metrics

      content {
        name = metric.value["name"]
        target = metric.value["target"]
        type = metric.value["type"]
      }
    }
  }

  depends_on = [google_compute_region_instance_group_manager.group]
}