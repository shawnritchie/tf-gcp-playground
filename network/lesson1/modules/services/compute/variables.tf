variable "project_id" {
  type                            = string
  description                     = "Project ID under which the VPC networks are to be created."
}

variable "instance_name" {
  type                            = string
  description                     = "Name of the instance to be created."
}

variable "machine_type" {
  type                            = string
  description                     = "Type of the instance to be created."
  default                         = "e2-medium"
}

variable "zone" {
  type                            = string
  description                     = "Zone in which the new instance will be created."
}

variable "nics" {
  type                            = list(object({
                                      network_name  = string
                                      subnet_name   = string
                                    }))
  description                     = "NICs to be connected to the new instance will be created."
}

