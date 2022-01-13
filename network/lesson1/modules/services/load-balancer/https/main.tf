terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
}

locals {
  is_internal = var.load_balancing_scheme == "INTERNAL" || var.load_balancing_scheme == "INTERNAL_MANAGED" ? true : false
  forwarding_rule_name = "${var.name}-http${var.enable_http ? "": "s"}-rule"
  port = var.enable_http ? "80" : "443"
}

# ------------------------------------------------------------------------------
# HOST RULES WHICH DEFINES THE HOST AND PATH WHICH WILL BE DELEGATED TO THE
# RIGHT BACKEND SERVICE
# ------------------------------------------------------------------------------

resource "google_compute_url_map" "urlmap" {
  count = var.region == null ? 1 : 0

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

resource "google_compute_region_url_map" "regional_urlmap" {
  count = var.region != null ? 1 : 0

  project      = var.project
  region       = var.region

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
# IF PLAIN HTTP ENABLED, CREATE HTTP PROXY
# ------------------------------------------------------------------------------

resource "google_compute_target_http_proxy" "global_http" {
  count   = var.enable_http && var.region == null ? 1 : 0

  project = var.project
  name    = "${var.name}-global-http-proxy"
  url_map = google_compute_url_map.urlmap[0].self_link

  depends_on = [google_compute_url_map.urlmap]
}

resource "google_compute_region_target_http_proxy" "regional_http" {
  count   = var.enable_http && var.region != null  ? 1 : 0

  project = var.project
  region = var.region
  name    = "${var.name}-regional-http-proxy"
  url_map = google_compute_region_url_map.regional_urlmap[0].self_link

  depends_on = [google_compute_url_map.urlmap]
}

# ------------------------------------------------------------------------------
# IF SSL ENABLED, CREATE HTTPS PROXY
# ------------------------------------------------------------------------------

resource "google_compute_target_https_proxy" "global_https" {
  count   = var.enable_ssl && var.region == null ? 1 : 0

  project = var.project
  name    = "${var.name}-global-https-proxy"
  url_map = google_compute_url_map.urlmap[0].self_link

  ssl_certificates = var.ssl_certificates

  depends_on = [google_compute_url_map.urlmap]
}

resource "google_compute_region_target_https_proxy" "regional_https" {
  count   = var.enable_ssl && var.region != null  ? 1 : 0

  project = var.project
  region = var.region
  name    = "${var.name}-regional-https-proxy"
  url_map = google_compute_region_url_map.regional_urlmap[0].self_link

  ssl_certificates = var.ssl_certificates

  depends_on = [google_compute_url_map.urlmap]
}

# ------------------------------------------------------------------------------
# IF GLOBAL ENABLED, CREATE FORWARDING RULE
# ------------------------------------------------------------------------------

resource "google_compute_global_forwarding_rule" "global" {
  provider   = google-beta

  count      = var.region == null ? 1 : 0

  project    = var.project
  name       = local.forwarding_rule_name
  target     = var.enable_http ? google_compute_target_http_proxy.global_http[0].self_link : google_compute_target_https_proxy.global_https[0].self_link
  ip_address = var.ip_address
  port_range = local.port

  labels = var.custom_labels
}

# ------------------------------------------------------------------------------
# IF REGIONAL ENABLED, CREATE FORWARDING RULE
# ------------------------------------------------------------------------------

resource "google_compute_forwarding_rule" "regional" {
  provider   = google-beta

  count      = var.region != null ? 1 : 0

  project    = var.project
  region     = var.region
  name       = local.forwarding_rule_name

  network_tier = var.network_tier
  load_balancing_scheme = var.load_balancing_scheme
  target     = var.enable_http ? google_compute_region_target_http_proxy.regional_http[0].self_link : google_compute_region_target_https_proxy.regional_https[0].self_link

  ip_protocol = "HTTP"
  network     = var.network
  subnetwork  = var.subnetwork
  ip_address  = var.ip_address
  port_range  = local.port

  labels      = var.custom_labels
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

  rrdatas = [var.ip_address]
}
