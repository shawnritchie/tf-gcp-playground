terraform {
  required_version = ">= 1.0"
}

resource "google_service_account" "service_account" {
  account_id   = var.account_name
  display_name = var.account_name
  project      = var.project_id
}

resource "google_cloud_identity_group_membership" "group_membership" {

  for_each = var.groups

  group    = each.value

  preferred_member_key {
    id = google_service_account.service_account.email
  }

  roles {
    name = "MEMBER"
  }

  depends_on = [google_service_account.service_account]
}