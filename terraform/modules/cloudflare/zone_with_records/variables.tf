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
    name  = string
    type  = string
    value = string
    ttl   = number
  }))
}
