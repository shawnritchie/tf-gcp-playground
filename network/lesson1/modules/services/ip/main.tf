terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
}

# ------------------------------------------------------------------------------
# CREATE A GLOBAL PUBLIC IP ADDRESS CAN ONLY BE USED ON PREMIUM NETWORK
# ------------------------------------------------------------------------------

resource "google_compute_global_address" "global_public_ip" {
  count = var.region == null ? 1 : 0

  project      = var.project
  name         = "${var.name}-address"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

# ------------------------------------------------------------------------------
# CREATE A REGIONAL PUBLIC IP ADDRESS
# ------------------------------------------------------------------------------
resource "google_compute_address" "regional_public_ip" {
  count = var.region != null && var.subnet_name == null ? 1 : 0

  project      = var.project
  region       = var.region
  name         = "${var.name}-address"
  address_type = "EXTERNAL"
  network_tier = var.network_tier
}

# ------------------------------------------------------------------------------
# CREATE A PRIVATE IP ADDRESS IN A PARTICULAR SUBNET
# ------------------------------------------------------------------------------

data "google_compute_subnetwork" "subnet" {
  count = var.region != null && var.subnet_name != null ? 1 : 0

  project = var.project
  region = var.region
  name = var.subnet_name
}


resource "google_compute_address" "private_ip" {
  count = var.region != null && var.subnet_name != null ? 1 : 0

  project      = var.project
  region       = var.region
  name         = "${var.name}-address"
  purpose      = "PRIVATE"
  address_type = "INTERNAL"
  subnetwork   = data.google_compute_subnetwork.subnet[0].id

  depends_on = [data.google_compute_subnetwork.subnet]
}
