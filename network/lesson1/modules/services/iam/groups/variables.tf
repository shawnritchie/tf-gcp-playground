variable "customer_id" {
  type        = string
  description = "GCP Customer Id"
}

variable "domain" {
  type        = string
  description = "Organisation Domain"
}

variable "group_name" {
  type        = string
  description = "Group name to be created"
}

variable "org_roles" {
  type        = set(string)
  description = "List of roles to be assigned to the group in the organisation"
  default     = []
}

