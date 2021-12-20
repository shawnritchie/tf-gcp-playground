output private_vpc_id {
  value = module.private-network.vpc_id
}

output public_vpc_id {
  value = module.public-network.vpc_id
}

output private_computer_resource_id {
  value = module.private-instance.computer_resource_id
}

output "private_nat" {
  value = module.private-instance.public_ip
}

output "private_instance_private_ips" {
  value = module.private-instance.private_ip
}

output public_computer_resource_id {
  value = module.public-instance.computer_resource_id
}

output "public_nat" {
  value = module.public-instance.public_ip
}

output "public_instance_private_ips" {
  value = module.public-instance.private_ip
}
