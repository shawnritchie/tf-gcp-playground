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