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

variable "ssh_key" {
  type = object({
    ssh_user            = string
    ssh_pub_key         = string
  })
  description = "User & Public key to use for ssh login"
  default = null
}

variable "os_login" {
  type        = bool
  description = "Should os login be enabled"
  default     = false
}

variable "nic0" {
  type = object({
    network_name        = string
    subnet_name         = optional(string)
    ephemeral_public_ip = optional(bool)
  })
  description = "nic0 Definition { name, region cidr } - DHCP connectivity"
  default = null
}

variable "nics" {
  type                            = list(object({
                                      network_name        = string
                                      subnet_name         = optional(string)
                                      ephemeral_public_ip = optional(bool)
                                    }))
  description                     = "NICs to be connected to the new instance will be created."
}