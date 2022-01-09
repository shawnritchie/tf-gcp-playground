terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
}


# ------------------------------------------------------------------------------
# CREATE A PUBLIC IP ADDRESS
# ------------------------------------------------------------------------------

resource "google_compute_global_address" "public_ip" {
  count = var.vpc_id == null ? 1 : 0

  project      = var.project
  name         = "${var.name}-address"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

# ------------------------------------------------------------------------------
# CREATE A PRIVATE IP ADDRESS
# ------------------------------------------------------------------------------

resource "google_compute_address" "private_ip" {
  count = var.vpc_id == null ? 0 : 1

  project      = var.project
  name         = "${var.name}-address"
  address_type = "INTERNAL"
  network      = var.vpc_id
}
