terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
}


# ------------------------------------------------------------------------------
# CREATE A PUBLIC IP ADDRESS
# ------------------------------------------------------------------------------

resource "google_compute_global_address" "default" {
  project      = var.project
  name         = "${var.name}-address"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

# ------------------------------------------------------------------------------
# HOST RULES WHICH DEFINES THE HOST AND PATH WHICH WILL BE DELEGATED TO THE
# RIGHT BACKEND SERVICE
# ------------------------------------------------------------------------------

resource "google_compute_url_map" "urlmap" {
  project      = var.project

  name        = "urlmap"
  default_service = var.default_service

  dynamic "host_rule" {
    for_each = {for name, host in var.host_rule: name => host.host}

    content {
      hosts = [host_rule.value]
      path_matcher = host_rule.key
    }
  }

  dynamic "path_matcher" {
    for_each = var.host_rule

    content {
      name = path_matcher.key
      default_service = path_matcher.value["default_service"]

      dynamic "path_rule" {
        for_each =  path_matcher.value["path_matcher"]

        content {
          paths = [path_rule.key]
          service = path_rule.value
        }
      }
    }
  }
}

# ------------------------------------------------------------------------------
# IF PLAIN HTTP ENABLED, CREATE FORWARDING RULE AND PROXY
# ------------------------------------------------------------------------------

resource "google_compute_target_http_proxy" "http" {
  count   = var.enable_http ? 1 : 0
  project = var.project
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.urlmap.self_link

  depends_on = [google_compute_url_map.urlmap]
}

resource "google_compute_global_forwarding_rule" "http" {
  provider   = google-beta
  count      = var.enable_http ? 1 : 0
  project    = var.project
  name       = "${var.name}-http-rule"
  target     = google_compute_target_http_proxy.http[0].self_link
  ip_address = google_compute_global_address.default.address
  port_range = "80"

  depends_on = [google_compute_global_address.default]

  labels = var.custom_labels
}

# ------------------------------------------------------------------------------
# IF SSL ENABLED, CREATE FORWARDING RULE AND PROXY
# ------------------------------------------------------------------------------

resource "google_compute_target_https_proxy" "default" {
  project = var.project
  count   = var.enable_ssl ? 1 : 0
  name    = "${var.name}-https-proxy"
  url_map = google_compute_url_map.urlmap.self_link

  ssl_certificates = var.ssl_certificates

  depends_on = [google_compute_url_map.urlmap]
}

resource "google_compute_global_forwarding_rule" "https" {
  provider   = google-beta
  project    = var.project
  count      = var.enable_ssl ? 1 : 0
  name       = "${var.name}-https-rule"
  target     = google_compute_target_https_proxy.default[0].self_link
  ip_address = google_compute_global_address.default.address
  port_range = "443"
  depends_on = [google_compute_global_address.default]

  labels = var.custom_labels
}

# ------------------------------------------------------------------------------
# IF DNS ENTRY REQUESTED, CREATE A RECORD POINTING TO THE PUBLIC IP OF THE CLB
# ------------------------------------------------------------------------------

resource "google_dns_record_set" "dns" {
  project = var.project
  count   = var.create_dns_entries ? length(var.custom_domain_names) : 0

  name = "${element(var.custom_domain_names, count.index)}."
  type = "A"
  ttl  = var.dns_record_ttl

  managed_zone = var.dns_managed_zone_name

  rrdatas = [google_compute_global_address.default.address]
}
