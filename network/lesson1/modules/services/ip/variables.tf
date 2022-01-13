# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------
variable "project" {
  description = "The project ID to create the resources in."
  type        = string
}

variable "name" {
  description = "Name for the load balancer forwarding rule and prefix for supporting resources."
  type        = string
}



# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------
variable "network_tier" {
  description = "The networking tier used for configuring this address. default: PREMIUM. PREMIUM | STANDARD"
  type = string
  default = "PREMIUM"
}

variable "region" {
  description = "region under which the ip will be issued"
  type        = string
  default     = null
}

variable "subnet_name" {
  description = "subnetwork name where the ip will be allocated"
  type        = string
  default     = null
}