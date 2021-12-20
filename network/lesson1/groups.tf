module "gcp-organization-admins" {
  source = "./modules/services/iam/groups"

  customer_id = var.customer_id
  domain      = var.domain
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
  source = "./modules/services/iam/groups"

  customer_id = var.customer_id
  domain      = var.domain
  group_name  = "gcp-network-admins"
  org_roles   = ["roles/compute.networkAdmin",
                "roles/compute.xpnAdmin",
                "roles/compute.securityAdmin",
                "roles/resourcemanager.folderViewer"]
}

module "gcp-billing-admins"  {
  source = "./modules/services/iam/groups"

  customer_id = var.customer_id
  domain      = var.domain
  group_name  = "gcp-billing-admins"
}

module "gcp-security-admins" {
  source = "./modules/services/iam/groups"

  customer_id = var.customer_id
  domain      = var.domain
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
  source = "./modules/services/iam/groups"

  customer_id = var.customer_id
  domain      = var.domain
  group_name  = "gcp-devops"
  org_roles   = ["roles/resourcemanager.folderViewer"]
}

module "gcp-developers"  {
  source = "./modules/services/iam/groups"

  customer_id = var.customer_id
  domain      = var.domain
  group_name  = "gcp-developers"
}
