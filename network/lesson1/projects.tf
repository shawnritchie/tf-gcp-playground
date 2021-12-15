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
  spinvadorsEmail = "@${local.domain}"
}


data "google_organization" "org" {
  domain = local.domain
}

module "project-vpc-host-dev" {
  source = "./modules/services/project"

  project_name    = "vpc-host-dev"
  billing_account = var.gcp_billing_account
  service_api     = []
  default_roles   = ["roles/owner"]
  folder_id       = module.dev_folder.folder_id
  members         = [
    "group:gcp-network-admins${local.spinvadorsEmail}"
  ]
}

module "project-vpc-host-prod" {
  source = "./modules/services/project"

  project_name    = "vpc-host-prod"
  billing_account = var.gcp_billing_account
  service_api     = []
  default_roles   = ["roles/owner"]
  folder_id       = module.production_folder.folder_id
  members         = [
    "group:gcp-network-admins${local.spinvadorsEmail}"
  ]
}