variable "project_id" {
  type = string
}

variable "group_name" {
  type = string
}

variable "template_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zones" {
  type                            = list(string)
  description                     = "Zone in which the new instance will be created."
}

variable "min_replicas" {
  type = number
}

variable "max_replicas" {
  type = number
}

variable "http_healthcheck" {
  type    = object({
    path = string
    port = number
  })
  default = null
}


variable "cpu_utilisation" {
  type = number
  default = null
}

variable "load_balancing_utilisation" {
  type = number
  default = null
}

variable "metrics" {
  type = list(object({
    name = string
    target = optional(number)
    type = optional(string)//GAUGE, DELTA_PER_SECOND, DELTA_PER_MINUTE
  }))
  default = []
}
