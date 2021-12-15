output "group_id" {
  value = google_cloud_identity_group.custom_group.id
}

output "gcp_group_ref" {
  value = google_cloud_identity_group.custom_group.name
}

output "group_name" {
  value = var.group_name
}