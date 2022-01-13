terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
}

# ------------------------------------------------------------------------------
# IF PLAIN HTTP ENABLED, CREATE FORWARDING RULE AND PROXY
# ------------------------------------------------------------------------------

resource "google_compute_target_tcp_proxy" "tcp_proxy" {
  project = var.project
  name            = "${var.name}-tcp-proxy"
  backend_service = var.default_service
}

resource "google_compute_global_forwarding_rule" "http" {
  provider   = google-beta
  count      = var.region == null ? 1 : 0

  project    = var.project
  name       = "${var.name}-tcp-rule"
  target     = google_compute_target_tcp_proxy.tcp_proxy.self_link

  ip_protocol = var.ip_protocol
  ip_address = var.ip_address
  port_range = var.port_range

  labels = var.custom_labels
}

resource "google_compute_forwarding_rule" "regional_forwaridng_rule" {
  provider   = google-beta
  count      = var.region != null ? 1 : 0

  project    = var.project
  name       = "${var.name}-tcp-rule"
  region     = var.region
  target     = google_compute_target_tcp_proxy.tcp_proxy.self_link

  ip_protocol = var.ip_protocol
  ip_address = var.ip_address
  port_range = var.port_range

  labels = var.custom_labels
}