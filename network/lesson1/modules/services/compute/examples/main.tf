terraform {
  required_version = ">= 1.0"
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

module "project_container" {
  source = "../../project"

  project_name = "compute-test"
  billing_account = var.billing_account
  service_api = ["compute.googleapis.com"]
  create_default_network = true
}

module "compute_instance" {
  source = "../"

  project_id = module.project_container.project_id
  instance_name = "test-instance"
  zone = "us-central1-a"
  nics = [{
    network_name  = "default"
//    subnet_name   = "10.128.0.0/20"
  }]

  depends_on = [module.project_container]
}