terraform {
  required_version = ">= 1.0"
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

module "us-network" {
  source = "../../../vpc"

  project_id = var.project_id
  vpc_name = "us-network"
  connect_to_default_internet_gateway = true

  vpc_subnets = {
    central = {
      name = "us-subnetwork"
      cidr = "10.128.0.0/20"
      region = "us-central1"
    }
  }

  ingress_rules = {
    allow-icmp = {
      source_ranges = [
        "0.0.0.0/0"]
      rules = [
        {
          protocol = "icmp"
        }]
    }
    allow-ssh = {
      source_ranges = [
        "0.0.0.0/0"]
      rules = [
        {
          protocol = "tcp"
          ports = [
            "22"]
        }]
    }
  }
}

module "us-instance" {
  source = "../../"

  project_id = var.project_id
  instance_name = "us-b-instance"
  zone = "us-central1-b"
  ssh_key = var.ssh_key

  nics = [
    {
      network_name = "us-network"
      subnet_name = "us-subnetwork"
      ephemeral_public_ip = true
    }
  ]

  depends_on = [
    module.us-network]
}