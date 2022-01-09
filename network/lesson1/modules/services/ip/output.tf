output "address" {
  description = "IP address of the Cloud Load Balancer"
  value       = var.vpc_id == null ? google_compute_global_address.public_ip[0].address : google_compute_address.private_ip[0].address
}