terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

locals {
  customerId = "C015bbxfj"
  domain     = "spinvadors.com"
}


data "google_organization" "org" {
  domain = local.domain
}

module "gcp-developers"  {
  source = "../../iam/groups"

  customer_id = local.customerId
  domain      = local.domain
  group_name  = "gcp-developers"
}

module "dev_folder" {
  source = "../../folder"

  folder_name   = "dev"
  folder_parent = data.google_organization.org.id

  members = ["group:gcp-developers@spinvadors.com"]
  roles = ["roles/compute.admin", "roles/container.admin"]

  depends_on = [module.gcp-developers]
}
