output us_a_vpc_id {
  value = module.us-a-network.vpc_id
}

output us_b_vpc_id {
  value = module.us-b-network.vpc_id
}

output us_a_computer_resource_id {
  value = module.us-a-instance.computer_resource_id
}

output "us_a_nat" {
  value = module.us-a-instance.public_ip
}

output "us_a_private_ips" {
  value = module.us-a-instance.private_ip
}

output us_b_computer_resource_id {
  value = module.us-b-instance.computer_resource_id
}

output "us_b_nat" {
  value = module.us-b-instance.public_ip
}

output "us_b_private_ips" {
  value = module.us-b-instance.private_ip
}
