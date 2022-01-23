output "project_id" {
  value = module.host_project_container.project_id
}

output "region" {
  value = module.asg_us.region
}

output "instance_group_id" {
  value = module.asg_us.instance_group_id
}

output "instance_group_name" {
  value = module.asg_us.instance_group_name
}

output "loadbalancer_ip" {
  value = module.private_ip.address
}