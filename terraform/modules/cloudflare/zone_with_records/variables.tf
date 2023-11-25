variable "account_id" {
  description = "The account ID to create the zone in"
  type        = string
}

variable "zone" {
  description = "The domain that describes the zone"
  type        = string
}

variable "zone_type" {
  description = "Whether the zone is partial or full"
  type        = string
  default     = "full"
}

variable "plan" {
  type    = string
  default = "free"
}

variable "records" {
  description = "A set of records the zone contains"
  type = set(object({
    name     = string
    type     = string
    value    = optional(string)
    ttl      = number
    priority = optional(number)
    data = optional(object({
      service  = string
      proto    = string
      name     = string
      priority = number
      weight   = number
      port     = number
    }))
  }))
}
