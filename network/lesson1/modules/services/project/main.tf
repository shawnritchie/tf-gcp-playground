terraform {
  required_version = ">= 1.0"
}

locals {
  policy = flatten([
    for role in var.default_roles: [
      for member in var.members: {
        role: role
        member: member
      }
    ]
  ])
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

  org_id              = var.org_id
  folder_id           = var.folder_id
}

resource "google_compute_project_default_network_tier" "network_tier" {
  project = google_project.gcp_project.project_id
  network_tier = var.network_tier

  depends_on = [google_project.gcp_project]
}

resource "google_project_iam_member" gcp_policy {
  for_each = {
    for p in local.policy: "${p.role}-${p.member}" => p
  }

  project = google_project.gcp_project.project_id
  role    = each.value.role
  member = each.value.member

  depends_on = [google_project.gcp_project]
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