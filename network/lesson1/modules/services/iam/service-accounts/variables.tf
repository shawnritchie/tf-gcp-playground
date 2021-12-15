variable account_name {
  type = string
  description = "Account Name which will be used for this service account."

  validation {
    condition     = can(regex("[a-z]([-a-z0-9]*[a-z0-9])", var.account_name))
    error_message = "The account_id value must be match the following regex expression [a-z]([-a-z0-9]*[a-z0-9])."
  }
}

variable project_id {
  type        = string
  description = "Project Id under which the service account will be created."
}

variable groups {
  type        = set(string)
  description = "Groups which the service account will be attributed with."
  default     = []
}