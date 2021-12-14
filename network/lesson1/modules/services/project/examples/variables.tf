variable "billing_account" {
  type        = string
  description = "GCP Billing Account"
}

variable "project_name" {
  type                            = string
  description                     = "Project name under which resources will be created"
  default                         = "test-project"
}

variable "service_api" {
  type        = list(string)
  description = "List of GCP APIs to be enabled for this account"
  default     = []
}