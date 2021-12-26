variable "project_id" {
  type                            = string
  description                     = "Project ID under which the VPC networks are to be created"
}

variable "vpc_name" {
  type                            = string
  description                     = "Name to be assigned to the created VPC"
}

variable "auto_create_subnetworks" {
  type                            = bool
  description                     = "Create default network with a subnet in every region"
  default                         = false
}

variable "connect_to_default_internet_gateway" {
  type                            = bool
  description                     = "Should the VPC have a route to the default internet gateway"
  default                         = false
}

variable "vpc_subnets" {
  type = map(object({
    name      = string
    region    = string
    cidr      = string
  }))
  description = "Subnet Definition { name, region cidr }"
  default = {}
}

variable "ingress_rules" {
  type = map(object({
    source_ranges             = optional(set(string))
    destination_ranges        = optional(set(string))
    source_tags               = optional(set(string))
    target_tags               = optional(set(string))
    source_service_accounts   = optional(set(string))
    target_service_accounts   = optional(set(string))
    rules                     = list(object({
                                  protocol = string
                                  ports = optional(set(string))
                                }))
  }))
  description = "Ingress rules to be applied to the VPC and subnets"
  default = {}
}