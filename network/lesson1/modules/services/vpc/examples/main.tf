terraform {
  required_version = ">= 1.0"
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

module "us-a-network" {
  source = "../"

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
      source_ranges = ["10.128.0.0/20", "10.130.0.0/20"]
      rules = [{
        protocol = "icmp"
      }]
    }
  }
}

module "us-b-network" {
  source = "../"

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
    allow-icmp-internal = {
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
}

module "us-a-instance" {
  source = "../../compute"

  project_id = var.project_id
  instance_name = "us-a-instance"
  zone = "us-central1-a"
  nics = [
    {
      network_name  = "us-a-network"
      subnet_name   = "us-a-subnetwork"
    }
  ]

  depends_on = [module.us-a-network]
}

module "us-b-instance" {
  source = "../../compute"

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

  depends_on = [module.us-b-network, module.us-a-network]
}
