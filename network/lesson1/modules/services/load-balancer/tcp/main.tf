terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
}

locals {
  internal = var.load_balancing_scheme == "INTERNAL" ? true : false
}

# ------------------------------------------------------------------------------
# IF PLAIN HTTP ENABLED, CREATE FORWARDING RULE AND PROXY
# ------------------------------------------------------------------------------

resource "google_compute_target_tcp_proxy" "tcp_proxy" {
  count      = !local.internal ? 1 : 0

  project = var.project
  name            = "${var.name}-tcp-proxy"
  backend_service = var.default_service
}

resource "google_compute_global_forwarding_rule" "http" {
  provider   = google-beta
  count      = var.region == null ? 1 : 0

  project    = var.project
  name       = "${var.name}-tcp-rule"
  target     = google_compute_target_tcp_proxy.tcp_proxy[0].self_link

  ip_protocol = var.ip_protocol
  ip_address = var.ip_address
  port_range = var.port_range

  labels = var.custom_labels
}

resource "google_compute_forwarding_rule" "regional_forwaridng_rule" {
  provider   = google-beta
  count      = var.region != null && !local.internal ? 1 : 0

  project    = var.project
  name       = "${var.name}-tcp-rule"
  region     = var.region
  load_balancing_scheme = var.load_balancing_scheme
  target      = google_compute_target_tcp_proxy.tcp_proxy[0].self_link

  ip_protocol = var.ip_protocol
  ip_address = var.ip_address
  port_range = var.port_range

  labels = var.custom_labels
}

resource "google_compute_forwarding_rule" "internal_forwaridng_rule" {
  provider   = google-beta
  count      = var.region != null && local.internal ? 1 : 0

  project    = var.project
  name       = "${var.name}-tcp-rule"
  region     = var.region

  load_balancing_scheme = var.load_balancing_scheme
  network     = var.network
  subnetwork  = var.subnetwork

  backend_service = var.default_service

  ip_protocol = var.ip_protocol
  ip_address = var.ip_address
  ports = var.ports

  labels = var.custom_labels
}