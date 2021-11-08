variable "gcp_region" {
  type        = string
  description = "GCP region"
  default     = "EU"
}

variable "gcp_billing_account" {
  type        = string
  description = "GCP Billing Account"
  default     = "01FC93-0961A0-D46A9E"
}

variable "project_name" {
  type                            = string
  description                     = "Project name under which resources will be created"
  default                         = "networking-lesson-new3"
}