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


//PRIVATE
module "us-a-network" {
  source = "../.."

  project_id = module.host_project_container.project_id
  vpc_name = "us-a-network"
  connect_to_default_internet_gateway = false

  vpc_subnets = {
    central = {
      name = "us-a-subnetwork"
      cidr = "10.130.0.0/20"
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
  }
}

//PUBLIC
module "us-b-network" {
  source = "../.."

  project_id = module.host_project_container.project_id
  vpc_name = "us-b-network"
  connect_to_default_internet_gateway = true

  vpc_subnets = {
    central = {
      name = "us-b-subnetwork"
      cidr = "10.128.0.0/20"
      region = "us-central1"
    }
  }

  ingress_rules = {
    allow-icmp = {
      source_ranges = ["0.0.0.0/0"]
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
}

module "vpc-peering" {
  source = "../../../peering"

  peer_networks = {
    public = module.us-b-network.vpc_id
    private = module.us-a-network.vpc_id
  }
}

//PRIVATE
module "us-a-instance" {
  source = "../../../compute"

  project_id = module.host_project_container.project_id
  instance_name = "us-a-instance"
  zone = "us-central1-a"

  nics = [
    {
      subnetwork_project = module.host_project_container.project_id
      subnet_name   = "us-a-subnetwork"
    }
  ]

  depends_on = [module.us-a-network]
}

//PUBLIC
module "us-b-instance" {
  source = "../../../compute"

  project_id = module.host_project_container.project_id
  instance_name = "us-b-instance"
  zone = "us-central1-b"
  os_login = true

  nics = [
    {
      subnetwork_project = module.host_project_container.project_id
      subnet_name         = "us-b-subnetwork"
      ephemeral_public_ip = true
    }
  ]

  depends_on = [module.us-b-network, module.us-a-network]
}
