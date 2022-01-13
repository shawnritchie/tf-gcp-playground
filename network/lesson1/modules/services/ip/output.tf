output "address" {
  description = "IP address of the Cloud Load Balancer"
  value       = concat(google_compute_global_address.global_public_ip, google_compute_address.regional_public_ip, google_compute_address.private_ip)[0].address
}