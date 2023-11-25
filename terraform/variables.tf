variable "grafana_password" {
  description = "The password for the grafana DB user"
  sensitive   = true
}
variable "immich_db_pass" {
  description = "The password for the immich postgres"
  sensitive   = true
}
