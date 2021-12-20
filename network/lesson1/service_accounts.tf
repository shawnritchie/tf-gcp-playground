module "sa-organization-admins" {
  source = "./modules/services/iam/service-accounts"

  account_name = "sa-organization-admins"
  project_id = module.project-vpc-host-prod.project_id
  groups = [module.gcp-organization-admins.group_id]
}

module "sa-network-admins" {
  source = "./modules/services/iam/service-accounts"

  account_name = "sa-network-admins"
  project_id = module.project-vpc-host-prod.project_id
  groups = [module.gcp-network-admins.group_id]
}

module "sa-billing-admins" {
  source = "./modules/services/iam/service-accounts"

  account_name = "sa-billing-admins"
  project_id = module.project-vpc-host-prod.project_id
  groups = [module.gcp-billing-admins.group_id]
}

module "sa-security-admins" {
  source = "./modules/services/iam/service-accounts"

  account_name = "sa-security-admins"
  project_id = module.project-vpc-host-prod.project_id
  groups = [module.gcp-security-admins.group_id]
}

module "sa-devops" {
  source = "./modules/services/iam/service-accounts"

  account_name = "sa-devops"
  project_id = module.project-vpc-host-dev.project_id
  groups = [module.gcp-devops.group_id]
}

module "sa-developers" {
  source = "./modules/services/iam/service-accounts"

  account_name = "sa-developers"
  project_id = module.project-vpc-host-dev.project_id
  groups = [module.gcp-developers.gcp_group_ref]

  depends_on = [module.project-vpc-host-dev, module.gcp-developers]
}
