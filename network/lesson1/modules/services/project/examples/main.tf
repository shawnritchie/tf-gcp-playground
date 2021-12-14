terraform {
  required_version = ">= 1.0"
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

module "project_container" {
  source = "../"

  project_name = var.project_name
  billing_account = var.billing_account
  service_api = var.service_api
  default_roles = [
    "roles/compute.networkViewer",
    "roles/compute.osLogin",
    "roles/compute.viewer"
  ]
}