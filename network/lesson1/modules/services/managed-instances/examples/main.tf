terraform {
  required_version = ">= 1.0"
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

module "host_project_container" {
  source = "../../project"

  project_name = "host-project"
  billing_account = var.billing_account
  service_api     = ["compute.googleapis.com"]
  default_roles   = ["roles/owner"]
}

module "vpc_network" {
  source = "../../vpc"

  project_id = module.host_project_container.project_id
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
    allow-http = {
      source_ranges = ["0.0.0.0/0"]
      rules = [{
        protocol = "tcp"
        ports = ["80"]
      }]
    }
  }

  depends_on = [module.host_project_container]
}

module "instance_template" {
  source = "../../managed-instances/template"

  project_id = module.host_project_container.project_id
  template_name = "privat-instance"
  region = "us-central1"

  tags = ["private"]
  os_login = true

  startup_script = <<EOT
  #!/bin/bash
  apt-get update
  apt-get install -y nginx
  service nginx start
  EOT

  nics = [{
    subnetwork_project  = module.host_project_container.project_id
    subnet_name         = "us-subnetwork"
    ephemeral_public_ip = true
  }]

  depends_on = [module.host_project_container, module.vpc_network]
}

module "autoscaling_group" {
  source = "../../managed-instances/group"

  project_id = module.host_project_container.project_id
  group_name = "asg"
  template_id = module.instance_template.template_id

  region = "us-central1"
  zones = ["us-central1-a", "us-central1-b"]

  min_replicas = 2
  max_replicas = 3

  cpu_utilisation = 0.7

  http_healthcheck = {
    path = "/"
    port = 80
  }

  depends_on = [module.host_project_container, module.vpc_network, module.instance_template]
}
