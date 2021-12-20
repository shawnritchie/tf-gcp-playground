variable "gcp_region" {
  type        = string
  description = "GCP region"
  default     = "EU"
}

variable "gcp_billing_account" {
  type        = string
  description = "GCP Billing Account"
  default     = "01B2E0-CE2A1C-88E698"
}

variable "domain" {
  type                            = string
  description                     = "Domain the organisation is linked too"
  default                         = "spinvadors.com"
}

variable "customer_id" {
  type                            = string
  description                     = "Customer Id which owns the organisation"
  default                         = "C015bbxfj"
}