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
  source = "../../../project"

  project_name    = "vpc-host-dev"
  billing_account = var.billing_account
  default_roles   = ["roles/owner"]
  org_id          = data.google_organization.org.org_id
}

module "sa-developers" {
  source = "../../service-accounts"

  account_name = "sa-developers"
  project_id = module.project-vpc-host-dev.project_id
  groups = []

  depends_on = [module.project-vpc-host-dev]
}
