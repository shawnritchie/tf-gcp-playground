module "production_folder" {
  source = "./modules/services/folder"

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
  source = "./modules/services/folder"

  folder_name   = "shared"
  folder_parent = module.production_folder.gcp_folder_ref

  depends_on = [module.production_folder]
}

module "dev_folder" {
  source = "./modules/services/folder"

  folder_name   = "dev"
  folder_parent = data.google_organization.org.id

  members = ["group:gcp-developers@spinvadors.com"]
  roles = ["roles/compute.admin", "roles/container.admin"]

  depends_on = [module.gcp-developers]
}

module "dev_shared_folder" {
  source = "./modules/services/folder"

  folder_name   = "shared"
  folder_parent = module.dev_folder.gcp_folder_ref

  depends_on = [module.dev_folder]
}