terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
}

# ------------------------------------------------------------------------------
# IF PLAIN HTTP ENABLED, CREATE FORWARDING RULE AND PROXY
# ------------------------------------------------------------------------------

resource "google_compute_ssl_certificate" "certificates" {
  count = length(var.certificates)

  name        = "cert-${count.index}"
  private_key = var.certificates[count.index].private_key
  certificate = var.certificates[count.index].certificate
}

resource "google_compute_target_ssl_proxy" "ssl_proxy" {
  project = var.project
  name            = "${var.name}-tcp-proxy"
  backend_service = var.default_service
  ssl_certificates = google_compute_ssl_certificate.certificates.id
}

resource "google_compute_global_forwarding_rule" "ssl" {
  provider   = google-beta

  project    = var.project
  name       = "${var.name}-tcp-rule"
  target     = google_compute_target_ssl_proxy.ssl_proxy.self_link

  ip_protocol = var.ip_protocol
  ip_address = var.ip_address
  port_range = var.port_range

  labels = var.custom_labels
}
