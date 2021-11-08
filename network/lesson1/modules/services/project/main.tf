terraform {
  required_version = ">= 1.0"
}

resource "random_string" "project_ext" {
  length           = 6
  special          = false
  upper            = false
  number           = true
}

resource "google_project" "gcp_project" {
  name                = var.project_name
  project_id          = format("%s-%s", var.project_name, random_string.project_ext.result)
  billing_account     = var.billing_account
  auto_create_network = var.create_default_network
}

resource "google_project_service" "enable_compute" {
  for_each = toset(var.service_api)

  project = google_project.gcp_project.project_id
  service = each.value
}

resource "null_resource" "wait_on_enable_compute" {
  provisioner "local-exec" {
    command = "sleep 60"
  }
  depends_on = [google_project_service.enable_compute]
}