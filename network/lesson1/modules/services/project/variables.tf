variable "project_name" {
  type                            = string
  description                     = "Project name under which resources will be created"
}

variable "billing_account" {
  type        = string
  description = "GCP Billing Account"
}

variable "service_api" {
  type = list(string)
  description = "List of GCP APIs to be enabled for this account"
}

variable "create_default_network" {
  type = bool
  description = "Should the project create default GCP network"
  default = false
}