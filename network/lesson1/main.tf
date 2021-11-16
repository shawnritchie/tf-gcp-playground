terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

provider "google" {
  region = var.gcp_region
}

locals {
  ingress = {
    allow-ssh = {
      source_ranges = ["0.0.0.0/0"]
      rules = [{
          protocol = "tcp"
          ports = ["22"]
        }]
    }
    allow-icmp = {
      source_ranges = flatten(
        [for net_name, network in local.networks: [
          for sub_name, subnet in network.subnets: subnet.cidr
        ]],
      )
      rules = [{
          protocol = "icmp"
        }]
    }
  }
  networks = {
    mynetwork = {
      network_name = "mynetwork"
      subnets = {
        subnet_A = {
          name = "mynetwork-10-128-0-0-twenty"
          cidr = "10.128.0.0/20"
          region = "us-central1"
        }
        subnet_B = {
          name = "mynetwork-10-132-0-0-twenty"
          cidr = "10.132.0.0/20"
          region = "europe-west1"
        }
      }
      ingress = {
        allow-https = {
          source_ranges = ["0.0.0.0/0"]
          rules = [{
            protocol = "tcp"
            ports = ["443"]
          }]
        }
      }
    }
    management = {
      network_name = "management"
      subnets = {
        subnet_A = {
          name = "management-10-130-0-0-twenty"
          cidr = "10.130.0.0/20"
          region = "europe-west1"
        }
      }
    }
    privatenet = {
      network_name = "privatenet"
      subnets = {
        subnet_A = {
          name = "privatenet-172-16-0-0-twentyfour"
          cidr = "172.16.0.0/24"
          region = "us-central1"
        }
        subnet_B = {
          name = "privatenet-172-20-0-0-twenty"
          cidr = "172.20.0.0/20"
          region = "europe-west1"
        }
      }
    }
  }
  compute = [
    {
      instance_name = "mynet-us-vm"
      zone = "us-central1-a"
      nics = [{
        network_name = local.networks.mynetwork.network_name
        subnet_name = local.networks.mynetwork.subnets.subnet_A.name
      }]
    },
    {
      instance_name = "mynet-eu-vm"
      zone = "europe-west1-b"
      nics = [{
          network_name = local.networks.mynetwork.network_name
          subnet_name = local.networks.mynetwork.subnets.subnet_B.name
        }]
    },
    {
      instance_name = "mgmt-eu-vm"
      zone = "europe-west1-b"
      machine_type = "e2-standard-4"
      nics = [{
          network_name = local.networks.management.network_name
          subnet_name = local.networks.management.subnets.subnet_A.name
        }, {
          network_name = local.networks.mynetwork.network_name
          subnet_name = local.networks.mynetwork.subnets.subnet_B.name
        }, {
        network_name = local.networks.privatenet.network_name
        subnet_name = local.networks.privatenet.subnets.subnet_B.name
      }]
    },
    {
      instance_name = "pnet-us-vm"
      zone = "us-central1-a"
      nics = [{
          network_name = local.networks.privatenet.network_name
          subnet_name = local.networks.privatenet.subnets.subnet_A.name
        }]
    },
    {
      instance_name = "pnet-eu-vm"
      zone = "europe-west1-b"
      nics = [{
          network_name = local.networks.privatenet.network_name
          subnet_name = local.networks.privatenet.subnets.subnet_B.name
        }]
    }
  ]
  peering = flatten([
    for from_network_name, from_network_id in module.networks: [
      for to_network_name, to_network_id in module.networks: {
        from_vpc_name   = from_network_name
        from_vpc_id     = from_network_id.vpc_id
        to_vpc_name     = to_network_name
        to_vpc_id       = to_network_id.vpc_id
      }
      if from_network_name != to_network_name
    ]
  ])
}

module "project_container" {
  source = "./modules/services/project"

  project_name = var.project_name
  billing_account = var.gcp_billing_account
  service_api = [
    "compute.googleapis.com"
  ]
}

module "networks" {
  for_each = local.networks

  source = "./modules/services/vpc"

  project_id = module.project_container.project_id
  vpc_name = each.value.network_name
  vpc_subnets = lookup(each.value, "subnets", {})
  ingress_rules = merge(local.ingress, lookup(each.value, "ingress", {}))

  depends_on = [module.project_container]
}

resource "google_compute_network_peering" "to" {
  for_each = {
    for peer in local.peering: "${peer.from_vpc_name}-${peer.to_vpc_name}" => peer
  }

  name         = each.key
  network      = each.value.from_vpc_id
  peer_network = each.value.to_vpc_id
}

module "instances" {
  source = "./modules/services/compute"

  for_each = {
    for compute in local.compute: compute.instance_name => compute
  }

  project_id = module.project_container.project_id
  instance_name = each.value.instance_name
  machine_type = lookup(each.value, "machine_type", "e2-medium")
  zone = each.value.zone

  nics = each.value.nics

  depends_on = [module.networks]
}