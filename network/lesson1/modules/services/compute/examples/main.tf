terraform {
  required_version = ">= 1.0"
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

module "compute_instance" {
  source = "../"

  project_id = var.project_id
  instance_name = "test-instance"
  zone = "us-central1-a"
  nics = [{
    network_name  = "default"
  }]
}