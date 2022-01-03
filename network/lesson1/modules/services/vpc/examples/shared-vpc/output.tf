output "shared_vpc_host_project" {
  value = module.host_project_container.project_id
}

output "shared_vpc_id" {
  value = module.host-network.vpc_id
}

output left_host_project {
  value = module.left_source_project_container.project_id
}

output left_compute_resource_id {
  value = module.left-instance.computer_resource_id
}

output left_compute_resource_nat {
  value = module.left-instance.public_ip
}

output left_compute_resource_private_ips {
  value = module.left-instance.private_ip
}

output right_host_project {
  value = module.right_source_project_container.project_id
}

output right_compute_resource_id {
  value = module.right-instance.computer_resource_id
}

output "right_compute_resource_nat" {
  value = module.right-instance.public_ip
}

output "right_compute_resource_private_ips" {
  value = module.right-instance.private_ip
}
