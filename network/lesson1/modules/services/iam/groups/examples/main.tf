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

module "gcp-organization-admins" {
  source = "../../groups"

  customer_id = local.customerId
  domain      = local.domain
  group_name  = "gcp-organization-admins"
  org_roles   = ["roles/resourcemanager.organizationAdmin",
                "roles/resourcemanager.folderAdmin",
                "roles/resourcemanager.projectCreator",
                "roles/billing.admin",
                "roles/iam.organizationRoleAdmin",
                "roles/orgpolicy.policyAdmin",
                "roles/securitycenter.admin",
                "roles/cloudsupport.admin"]
}

module "gcp-network-admins" {
  source = "../../groups"

  customer_id = local.customerId
  domain      = local.domain
  group_name  = "gcp-network-admins"
  org_roles   = ["roles/compute.networkAdmin",
                "roles/compute.xpnAdmin",
                "roles/compute.securityAdmin",
                "roles/resourcemanager.folderViewer"]
}

module "gcp-billing-admins"  {
  source = "../../groups"
  customer_id = local.customerId
  domain      = local.domain
  group_name  = "gcp-billing-admins"
}

module "gcp-security-admins" {
  source = "../../groups"

  customer_id = local.customerId
  domain      = local.domain
  group_name  = "gcp-security-admins"
  org_roles   = ["roles/orgpolicy.policyAdmin",
                "roles/orgpolicy.policyViewer",
                "roles/iam.securityReviewer",
                "roles/iam.organizationRoleViewer",
                "roles/securitycenter.admin",
                "roles/resourcemanager.folderIamAdmin",
                "roles/logging.privateLogViewer",
                "roles/logging.configWriter",
                "roles/container.viewer",
                "roles/compute.viewer",
                "roles/bigquery.dataViewer"]
}

module "gcp-devops"  {
  source = "../../groups"

  customer_id = local.customerId
  domain      = local.domain
  group_name  = "gcp-devops"
  org_roles   = ["roles/resourcemanager.folderViewer"]
}

module "gcp-developers"  {
  source = "../../groups"

  customer_id = local.customerId
  domain      = local.domain
  group_name  = "gcp-developers"
}

module "production_folder" {
  source = "../../../folder"

  folder_name   = "production"
  folder_parent = data.google_organization.org.id

  members = ["group:gcp-devops@spinvadors.com"]
  roles = [
    "roles/logging.admin",
    "roles/errorreporting.admin",
    "roles/servicemanagement.quotaAdmin",
    "roles/monitoring.admin",
    "roles/compute.admin",
    "roles/container.admin"
  ]

  depends_on = [module.gcp-devops]
}

module "production_shared_folder" {
  source = "../../../folder"

  folder_name   = "shared"
  folder_parent = module.production_folder.gcp_folder_ref

  depends_on = [module.production_folder]
}

module "dev_folder" {
  source = "../../../folder"

  folder_name   = "dev"
  folder_parent = data.google_organization.org.id

  members = ["group:gcp-developers@spinvadors.com"]
  roles = ["roles/compute.admin", "roles/container.admin"]

  depends_on = [module.gcp-developers]
}

module "dev_shared_folder" {
  source = "../../../folder"

  folder_name   = "shared"
  folder_parent = module.dev_folder.gcp_folder_ref

  depends_on = [module.dev_folder]
}

module "project-vpc-host-dev" {
  source = "../../../../../modules/services/project"

  project_name    = "vpc-host-dev"
  billing_account = var.billing_account
  service_api     = []
  default_roles   = ["roles/owner"]
  folder_id       = module.dev_folder.folder_id
  members         = [
    "group:gcp-network-admins${local.spinvadorsEmail}"
  ]
}

module "project-vpc-host-prod" {
  source = "../../../../../modules/services/project"

  project_name    = "vpc-host-prod"
  billing_account = var.billing_account
  service_api     = []
  default_roles   = ["roles/owner"]
  folder_id       = module.production_folder.folder_id
  members         = [
    "group:gcp-network-admins${local.spinvadorsEmail}"
  ]
}

module "sa-organization-admins" {
  source = "../../service-accounts"

  account_name = "sa-organization-admins"
  project_id = module.project-vpc-host-prod.project_id
  groups = [module.gcp-organization-admins.group_id]
}

module "sa-network-admins" {
  source = "../../service-accounts"

  account_name = "sa-network-admins"
  project_id = module.project-vpc-host-prod.project_id
  groups = [module.gcp-network-admins.group_id]
}

module "sa-billing-admins" {
  source = "../../service-accounts"

  account_name = "sa-billing-admins"
  project_id = module.project-vpc-host-prod.project_id
  groups = [module.gcp-billing-admins.group_id]
}

module "sa-security-admins" {
  source = "../../service-accounts"

  account_name = "sa-security-admins"
  project_id = module.project-vpc-host-prod.project_id
  groups = [module.gcp-security-admins.group_id]
}

module "sa-devops" {
  source = "../../service-accounts"

  account_name = "sa-devops"
  project_id = module.project-vpc-host-dev.project_id
  groups = [module.gcp-devops.group_id]
}

module "sa-developers" {
  source = "../../service-accounts"

  account_name = "sa-developers"
  project_id = module.project-vpc-host-dev.project_id
  groups = [module.gcp-developers.gcp_group_ref]

  depends_on = [module.project-vpc-host-dev, module.gcp-developers]
}
