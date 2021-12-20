terraform {
  required_version = ">= 1.0"
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

module "private-network" {
  source = "../.."

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
      source_tags = ["public-instance"]
      rules = [{
        protocol = "icmp"
      }]
    }
  }
}

module "public-network" {
  source = "../.."

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
    allow-ssh = {
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["public-instance"]
      rules = [{
        protocol = "tcp"
        ports = ["22"]
      }]
    }
    allow-icmp-internal = {
      source_tags = ["public-instance", "private-instance"]
      rules = [{
        protocol = "icmp"
      }]
    }
  }
}

module "private-instance" {
  source = "../../../compute"

  project_id = var.project_id
  instance_name = "private-instance"
  tags = ["private-instance"]
  zone = "us-central1-a"
  nics = [
    {
      network_name  = "us-a-network"
      subnet_name   = "us-a-subnetwork"
    }
  ]

  depends_on = [module.private-network]
}

module "public-instance" {
  source = "../../../compute"

  project_id = var.project_id
  instance_name = "public-instance"
  tags = ["public-instance"]
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

  depends_on = [module.public-network, module.private-network]
}
