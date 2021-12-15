variable "folder_name" {
  type        = string
  description = "Folder name to be created"
}

variable "folder_parent" {
  type        = string
  description = "The resource name of the parent Folder or Organization"

  validation {
    condition = length(regexall("folders/.+|organizations/.+", var.folder_parent)) > 0
    error_message = "Required Form: folders/{folder_id} or organizations/{org_id}."
  }
}

variable "roles" {
  type        = set(string)
  description = "roles to be assigned to the folder"
  default     = []
}

variable "members" {
  type        = set(string)
  description = "members which will be given the roles specified for this folder"
  default     = []

  validation {
    condition = alltrue([for member in var.members: (length(regexall("user:.+|serviceAccount:.+|group:.+|domain.+", member)) > 0)])
    error_message = "Values must match expression user:{emailid} | serviceAccount:{emailid} | group:{emailid} | domain:{domain}."
  }
}