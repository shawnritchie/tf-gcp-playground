locals {
  spinvadorsEmail = "@${var.domain}"
}

module "project-vpc-host-dev" {
  source = "./modules/services/project"

  project_name    = "vpc-host-dev"
  billing_account = var.gcp_billing_account
  service_api     = ["compute.googleapis.com"]
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
  service_api     = ["compute.googleapis.com"]
  default_roles   = ["roles/owner"]
  folder_id       = module.production_folder.folder_id
  members         = [
    "group:gcp-network-admins${local.spinvadorsEmail}"
  ]
}