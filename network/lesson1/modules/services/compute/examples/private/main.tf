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
}

module "compute_instance" {
  source = "../../"

  project_id = var.project_id
  instance_name = "test-instance"
  zone = "us-central1-a"
  nics = [{
    network_name  = "us-network"
    subnet_name   = "us-subnetwork"
  }]

  depends_on = [module.us-network]
}