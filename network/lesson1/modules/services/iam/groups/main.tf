terraform {
  required_version = ">= 1.0"
}

locals {
  group_email = "${var.group_name}@${var.domain}"
}

data "google_organization" "org" {
  domain = var.domain
}

resource "google_cloud_identity_group" "custom_group" {
  display_name = var.group_name
  initial_group_config = "EMPTY"

  parent = "customers/${var.customer_id}"

  group_key {
    id = local.group_email
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

resource "google_organization_iam_member" "organization_group_roles" {
  for_each = var.org_roles

  org_id  = data.google_organization.org.org_id
  role    = each.value
  member = "group:${local.group_email}"

  depends_on = [google_cloud_identity_group.custom_group]
}