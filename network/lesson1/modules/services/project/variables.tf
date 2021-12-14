variable "project_name" {
  type                            = string
  description                     = "Project name under which resources will be created"
}

variable "billing_account" {
  type        = string
  description = "GCP Billing Account"
}

variable "service_api" {
  type        = list(string)
  description = "List of GCP APIs to be enabled for this account"
  default     = []
}

variable "create_default_network" {
  type = bool
  description = "Should the project create default GCP network"
  default = false
}

variable "members" {
  type = list(string)
  description = "List of members to be privileged the mentioned roles"
  default = []
}

variable "default_roles" {
  type = list(string)
  description = "List of roles to be inherited in the project"
  default = []
}

variable "org_id" {
  type = string
  description = "Organisation ID under which the project will be created"
  default = null
}

variable "folder_id" {
  type = string
  description = "Organisation ID under which the project will be created"
  default = null
}