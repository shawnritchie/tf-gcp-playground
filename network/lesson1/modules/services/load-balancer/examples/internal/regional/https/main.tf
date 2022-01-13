terraform {
  required_version = ">= 1.0"
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

locals {
  region = "us-west1"
  zones = ["us-west1-a", "us-west1-b"]
}

module "host_project_container" {
  source = "../../../../../project"

  project_name = "host-project"
  billing_account = var.billing_account
  service_api     = ["compute.googleapis.com"]
  default_roles   = ["roles/owner"]
}

module "vpc_network" {
  source = "../../../../../vpc"

  project_id = module.host_project_container.project_id
  vpc_name = "us-network"
  connect_to_default_internet_gateway = true
  routing_mode = "REGIONAL"

  vpc_subnets = {
    instance = {
      name = "us-compute-subnetwork"
      cidr = "10.128.0.0/20"
      region = local.region
    }
    proxy = {
      name = "us-proxy-subnetwork"
      cidr = "10.130.0.0/20"
      region = local.region
      purpose = "INTERNAL_HTTPS_LOAD_BALANCER"
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

data "google_compute_subnetwork" "us-proxy-subnetwork" {
  project = module.host_project_container.project_id
  region = local.region
  name = "us-proxy-subnetwork"

  depends_on = [module.vpc_network]
}

data "google_compute_subnetwork" "us-compute-subnetwork" {
  project = module.host_project_container.project_id
  region = local.region
  name = "us-compute-subnetwork"

  depends_on = [module.vpc_network]
}

module "private_ip" {
  source = "../../../../../ip"

  project = module.host_project_container.project_id
  name = "internal-lb-ip"
  region = local.region
  subnet_name = "us-compute-subnetwork"

  depends_on = [data.google_compute_subnetwork.us-compute-subnetwork]
}

module "instance_template" {
  source = "../../../../../managed-instances/template"

  project_id = module.host_project_container.project_id
  template_name = "privat-instance"
  region = local.region

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
    subnet_name         = "us-compute-subnetwork"
    ephemeral_public_ip = true
  }]

  depends_on = [module.host_project_container, module.vpc_network]
}

resource "google_compute_health_check" "global_health_check" {
  project = module.host_project_container.project_id

  name = "nginx-global-healthcheck"
  check_interval_sec = 5
  timeout_sec = 5
  healthy_threshold = 2
  unhealthy_threshold = 5

  http_health_check {
    request_path  = "/"
    port          = 80
  }

  log_config {
    enable = true
  }
}

resource "google_compute_region_health_check" "health_check" {
  project = module.host_project_container.project_id
  region = local.region

  name = "nginx-healthcheck"
  check_interval_sec = 5
  timeout_sec = 5
  healthy_threshold = 2
  unhealthy_threshold = 5

  http_health_check {
    request_path  = "/"
    port          = 80
  }

  log_config {
    enable = true
  }
}

module "asg_us" {
  source = "../../../../../managed-instances/group"

  project_id = module.host_project_container.project_id
  group_name = "asg-us"
  template_id = module.instance_template.template_id

  region = local.region
  zones = local.zones

  min_replicas = 2
  max_replicas = 3

  cpu_utilisation = 0.7

  named_port = {
    http: 80
  }

  health_checks = [google_compute_health_check.global_health_check.id]

  depends_on = [module.host_project_container, module.vpc_network, module.instance_template]
}

resource "google_compute_region_backend_service" "default" {
  provider = google-beta

  project                         = module.host_project_container.project_id
  region                          = local.region
  name                            = "backend-service"
  load_balancing_scheme           = "INTERNAL_MANAGED"
  protocol                        = "HTTP"
  session_affinity                = "NONE"

  timeout_sec                     = 10
  connection_draining_timeout_sec = 10

  health_checks = [google_compute_region_health_check.health_check.id]

  backend {
    balancing_mode = "UTILIZATION"
    group = module.asg_us.instance_group
    capacity_scaler = 1.0
  }

  depends_on = [module.asg_us, google_compute_region_health_check.health_check]
}

module "regional_load_balancer" {
  source = "../../../../../load-balancer/https"

  name = "http-nginx-lb"
  project = module.host_project_container.project_id
  default_service = google_compute_region_backend_service.default.self_link

  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = module.vpc_network.vpc_id
  subnetwork            = data.google_compute_subnetwork.us-compute-subnetwork.id
  ip_address            = module.private_ip.address
  region                = local.region

  host_rule = {
    any: {
      host = "*"
      default_service = google_compute_region_backend_service.default.self_link
      path_matcher = {
        "/": google_compute_region_backend_service.default.self_link
      }
    }
  }

  depends_on = [google_compute_region_backend_service.default]
}
