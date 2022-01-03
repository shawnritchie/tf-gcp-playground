output "region" {
  value = var.region
}

output "instance_group_id" {
  value = google_compute_region_instance_group_manager.group.id
}

output "instance_group_name" {
  value = google_compute_region_instance_group_manager.group.name
}

output "instance_group" {
  value = google_compute_region_instance_group_manager.group.instance_group
}
