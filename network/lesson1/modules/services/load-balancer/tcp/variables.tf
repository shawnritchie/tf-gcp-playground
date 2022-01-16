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

variable "ip_address" {
  description = "ip address which will direct traffic towards the load balancer"
  type = string
}

variable "ip_protocol" {
  description = "The IP protocol to which this rule applies. When the load balancing scheme is INTERNAL, only TCP and UDP are valid. Possible values are TCP, UDP, ESP, AH, SCTP, ICMP, and L3_DEFAULT"
  type = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "load_balancing_scheme" {
  description = "This signifies what the ForwardingRule will be used for and can be EXTERNAL, INTERNAL"
  type = string
  default = "EXTERNAL"

  validation {
    condition = contains(["EXTERNAL","INTERNAL"], var.load_balancing_scheme)
    error_message = "Required Form: [EXTERNAL, INTERNAL]."
  }
}

variable port_range {
  description = "Used explicit only for external tcp load balancers e.g. 8081-8090"
  type = string
  default = null
}

variable ports {
  description = "Used explicit only for internal tcp load balancers e.g. [80,8080]"
  type = list(string)
  default = null
}

variable "custom_labels" {
  description = "A map of custom labels to apply to the resources. The key is the label name and the value is the label value."
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "Regional load balancer to be created in the following region"
  type        = string
  default     = null
}

variable "network" {
  description = " For internal load balancing, this field identifies the network that the load balanced IP should belong to for this Forwarding Rule"
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "subnetwork name where the ip will be allocated"
  type        = string
  default     = null
}