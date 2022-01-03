terraform {
  required_version = ">= 1.0"
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

module "host_project_container" {
  source = "../../../project"

  project_name = "host-project"
  billing_account = var.billing_account
  service_api     = ["compute.googleapis.com"]
  default_roles   = ["roles/owner"]
}

module "left_source_project_container" {
  source = "../../../project"

  project_name = "left-source-project"
  billing_account = var.billing_account
  service_api     = ["compute.googleapis.com"]
  default_roles   = ["roles/owner"]
}

module "right_source_project_container" {
  source = "../../../project"

  project_name = "right-source-project"
  billing_account = var.billing_account
  service_api     = ["compute.googleapis.com"]
  default_roles   = ["roles/owner"]
}

module "host-network" {
  source = "../.."

  project_id = module.host_project_container.project_id
  vpc_name = "host-network"
  connect_to_default_internet_gateway = true

  vpc_subnets = {
    left = {
      name = "left-subnetwork"
      cidr = "10.130.0.0/20"
      region = "us-central1"
    }
    right = {
      name = "right-subnetwork"
      cidr = "10.128.0.0/20"
      region = "us-central1"
    }
  }

  ingress_rules = {
    allow-icmp = {
      source_ranges = ["10.128.0.0/20", "10.130.0.0/20"]
      rules = [{
        protocol = "icmp"
      }]
    }
    allow-ssh = {
      source_ranges = ["0.0.0.0/0"]
      rules = [{
        protocol = "tcp"
        ports = ["22"]
      }]
    }
  }

  shared_vpc_service_projects = {
    right = module.right_source_project_container.project_id
    left = module.left_source_project_container.project_id
  }

  depends_on = [module.host_project_container, module.right_source_project_container, module.left_source_project_container]
}

module "left-instance" {
  source = "../../../compute"

  project_id = module.left_source_project_container.project_id
  instance_name = "left-instance"
  zone = "us-central1-a"

  nics = [
    {
      subnetwork_project  = module.host_project_container.project_id
      subnet_name   = "left-subnetwork"
    }
  ]

  depends_on = [module.host_project_container, module.host-network, module.left_source_project_container]
}

module "right-instance" {
  source = "../../../compute"

  project_id = module.right_source_project_container.project_id
  instance_name = "right-instance"
  zone = "us-central1-a"
  os_login = true

  nics = [
    {
      subnetwork_project  = module.host_project_container.project_id
      subnet_name         = "right-subnetwork"
      ephemeral_public_ip = true
    }
  ]

  depends_on = [module.host_project_container, module.host-network, module.right_source_project_container]
}
