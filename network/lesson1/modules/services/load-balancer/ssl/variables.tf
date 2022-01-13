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

variable "default_service" {
  description = "default backend service to be used"
  type = string
}

variable "certificates" {
  description = "This resource provides a mechanism to upload an SSL key and certificate to the load balancer to serve secure connections from the user."
  type = list(object({
    private_key = string
    certificate = string
  }))
}

variable "ip_address" {
  description = "ip address which will direct traffic towards the load balancer"
  type = string
}

variable "ip_protocol" {
  description = "The IP protocol to which this rule applies. When the load balancing scheme is INTERNAL, only TCP and UDP are valid. Possible values are TCP, UDP, ESP, AH, SCTP, ICMP, and L3_DEFAULT"
  type = string
}

variable port_range {
  description = "8081-8090"
  type = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "custom_labels" {
  description = "A map of custom labels to apply to the resources. The key is the label name and the value is the label value."
  type        = map(string)
  default     = {}
}
