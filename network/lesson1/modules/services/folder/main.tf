terraform {
  required_version = ">= 1.0"
}

locals {
  flattened_member_roles = flatten([ for member in var.members: [
      for role in var.roles: {
        member: member
        role: role
      }
  ]])
}

resource "google_folder" "org_folders" {
  display_name = var.folder_name
  parent       = var.folder_parent
}

resource "google_folder_iam_member" "folder" {
  for_each = {for mr in local.flattened_member_roles: "${mr.member}-${mr.role}" => mr}

  folder =google_folder.org_folders.id
  role   = each.value.role
  member = each.value.member

  depends_on = [google_folder.org_folders]
}
