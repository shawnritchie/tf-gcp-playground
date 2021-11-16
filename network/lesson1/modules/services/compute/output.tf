output "computer_resource_id" {
  value = google_compute_instance.compute_instance.id
}

output "address" {
  description = "The public IP of the bastion host."
  value       = flatten([
                  for nic in google_compute_instance.compute_instance.network_interface:
                    [for nat in nic.access_config: nat.nat_ip]
                  if length(nic.access_config) > 0
                ])
}

output "private_ip" {
  description = "The private IP of the bastion host."
  value       = [for nic in google_compute_instance.compute_instance.network_interface: nic.network_ip]
}