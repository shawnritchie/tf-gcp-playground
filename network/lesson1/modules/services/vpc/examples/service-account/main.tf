terraform {
  required_version = ">= 1.0"
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

module "source-sa" {
  source = "../../../iam/service-accounts"

  account_name = "source-sa"
  project_id   = var.project_id
}

module "target-sa" {
  source = "../../../iam/service-accounts"

  account_name = "destination-sa"
  project_id   = var.project_id
}

//PRIVATE
module "us-a-network" {
  source = "../../../vpc"

  project_id = var.project_id
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
      source_service_accounts = [module.source-sa.email]
      target_service_accounts = [module.target-sa.email]
      rules = [{
        protocol = "icmp"
      }]
    }
  }

  depends_on = [module.target-sa, module.source-sa]
}

//PUBLIC
module "us-b-network" {
  source = "../../../vpc"

  project_id = var.project_id
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

//PRIVATE
module "us-a-instance" {
  source = "../../../compute"

  project_id = var.project_id
  instance_name = "us-a-instance"
  zone = "us-central1-a"
  nics = [
    {
      network_name  = "us-a-network"
      subnet_name   = "us-a-subnetwork"
    }
  ]

  service_account = {
    email = module.target-sa.email
    scopes = ["cloud-platform"]
  }

  depends_on = [module.us-a-network]
}

//PUBLIC
module "us-b-instance" {
  source = "../../../compute"

  project_id = var.project_id
  instance_name = "us-b-instance"
  zone = "us-central1-b"
  os_login = true

  nic0 = {
    network_name        = "us-b-network"
    subnet_name         = "us-b-subnetwork"
    ephemeral_public_ip = true
  }

  nics = [
    {
      network_name  = "us-a-network"
      subnet_name   = "us-a-subnetwork"
    }
  ]

  service_account = {
    email = module.source-sa.email
    scopes = ["cloud-platform"]
  }

  depends_on = [module.us-b-network, module.us-a-network]
}
