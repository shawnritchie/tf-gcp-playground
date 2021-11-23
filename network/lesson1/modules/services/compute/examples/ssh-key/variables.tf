variable "project_id" {
  type        = string
  description = "GCP Project ID"
  default     = "tf-state-329314"
}

variable "ssh_key" {
  type = object({
    ssh_user            = string
    ssh_pub_key         = string
  })
  description = "User & Public key to use for ssh login"
  default = null
}