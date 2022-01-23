output "project_id" {
  value = module.host_project_container.project_id
}

output "loadbalancer_ip" {
  value = module.public_ip.address
}