terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
}

resource "google_compute_instance" "compute_instance" {
  project       = var.project_id
  name          = var.instance_name
  machine_type  = var.machine_type
  zone          = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  dynamic "network_interface" {
    for_each = {
      for nic in var.nics: "${nic.network_name}.${coalesce(nic.subnet_name,"default")}" => nic
    }

    content {
      network             = network_interface.value["network_name"]
      subnetwork_project  = var.project_id
      subnetwork          = network_interface.value["subnet_name"]
    }
  }
}



