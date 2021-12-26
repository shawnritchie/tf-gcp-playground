terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
}

resource "google_compute_network" "vpc_network" {
  project                           = var.project_id
  name                              = var.vpc_name
  routing_mode                      = "REGIONAL"
  auto_create_subnetworks           = false
  delete_default_routes_on_create   = !var.connect_to_default_internet_gateway
  mtu                               = 1460
}

resource "google_compute_subnetwork" "vpc_network_subnet" {
  for_each      = var.vpc_subnets

  project       = var.project_id
  name          = each.value.name
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "ingress_rules" {
  for_each        = var.ingress_rules

  project         = var.project_id
  name            = format("%s-%s", var.vpc_name, each.key)
  network         = google_compute_network.vpc_network.id
  direction       = "INGRESS"
  source_ranges   = each.value.source_ranges

  source_tags     = each.value.source_tags
  target_tags     = each.value.target_tags

  source_service_accounts = each.value.source_service_accounts
  target_service_accounts = each.value.target_service_accounts

  dynamic "allow" {
    for_each = each.value.rules

    content {
      protocol  = allow.value["protocol"]
      ports     = allow.value["ports"]
    }
  }

  depends_on = [google_compute_network.vpc_network]
}