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

variable "health_checks" {
  type = list(string)
  description = "List of google_compute_health_check.x.ids which the auto scaling group instances will be checked against for health"
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

variable "named_port" {
  description = "named port mapping http: 80, https: 443"
  type = map(number)
  default = null
}