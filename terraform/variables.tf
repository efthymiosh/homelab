variable "grafana_password" {
  description = "The password for the grafana DB user"
  sensitive   = true
}
variable "minio_access_key_id" {
  sensitive = true
}

variable "minio_secret_access_key" {
  sensitive = true
}
