output "project_id" {
  value = module.host_project_container.project_id
}

output "region" {
  value = module.autoscaling_group.region
}

output "instance_group_id" {
  value = module.autoscaling_group.instance_group_id
}

output "instance_group_name" {
  value = module.autoscaling_group.instance_group_name
}
