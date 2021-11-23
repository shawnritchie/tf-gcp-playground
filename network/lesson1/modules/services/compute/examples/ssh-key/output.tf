output us_vpc_id {
  value = module.us-network.vpc_id
}

output us_computer_resource_id {
  value = module.us-instance.computer_resource_id
}

output "us_nat" {
  value = module.us-instance.public_ip
}

output "us_private_ips" {
  value = module.us-instance.private_ip
}