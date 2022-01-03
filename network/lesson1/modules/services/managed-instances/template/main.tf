terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
}

resource "google_compute_instance_template" "instance_template" {
  name_prefix = var.template_name

  project       = var.project_id
  machine_type  = var.machine_type

  tags          = var.tags
  region        = var.region

  disk {
    auto_delete = true
    boot = true
    source_image = "debian-cloud/debian-9"
  }

  metadata = merge(
  {enable-oslogin = var.os_login},
  var.ssh_key != null ? {
    ssh-keys = <<EOT
        ${var.ssh_key.ssh_user}:${var.ssh_key.ssh_pub_key}
        EOT
  } : {}
  )

  metadata_startup_script = var.startup_script

  dynamic "network_interface" {
    for_each = var.nic0 == null ? [] : [var.nic0]

    content {
      network             = network_interface.value["network_name"]
      subnetwork_project  = network_interface.value["subnetwork_project"]
      subnetwork          = network_interface.value["subnet_name"]

      dynamic "access_config" {
        for_each = toset(coalesce(network_interface.value["ephemeral_public_ip"], false) ? [""] : [])
        content {}
      }
    }
  }


  dynamic "network_interface" {
    for_each = {
    for nic in var.nics: "${coalesce(nic.network_name,"default")}.${coalesce(nic.subnetwork_project,"default")}.${coalesce(nic.subnet_name,"default")}" => nic
    }

    content {
      network             = network_interface.value["network_name"]
      subnetwork_project  = network_interface.value["subnetwork_project"]
      subnetwork          = network_interface.value["subnet_name"]

      dynamic "access_config" {
        for_each = toset(coalesce(network_interface.value["ephemeral_public_ip"], false) ? [""] : [])
        content {}
      }
    }
  }

  dynamic "service_account" {
    for_each = var.service_account == null ? {} : {sa: var.service_account}

    content {
      email = service_account.value["email"]
      scopes = service_account.value["scopes"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}