terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
}

resource "google_compute_network" "vpc_network" {
  project                           = var.project_id
  name                              = var.vpc_name
  routing_mode                      = var.routing_mode
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
  purpose       = each.value.purpose
  role          = each.value.purpose != null ? "ACTIVE" : null
}

resource "google_compute_firewall" "ingress_rules" {
  for_each        = var.ingress_rules

  project         = var.project_id
  name            = format("%s-%s", var.vpc_name, each.key)
  network         = google_compute_network.vpc_network.id
  direction       = "INGRESS"

  source_ranges   = each.value.source_ranges
  destination_ranges = each.value.destination_ranges

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

resource "google_compute_shared_vpc_host_project" "shared_vpc_host_project" {
  count = length(var.shared_vpc_service_projects) > 0 ? 1 : 0

  project = var.project_id
}

resource "google_compute_shared_vpc_service_project" "shared_vpc_service_projects" {
  for_each = var.shared_vpc_service_projects

  host_project = var.project_id
  service_project = each.value

  depends_on = [google_compute_shared_vpc_host_project.shared_vpc_host_project]
}