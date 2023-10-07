variable "grafana_password" {
  description = "The password for the grafana DB user"
  sensitive   = true
}
variable "immich_db_pass" {
  description = "The password for the immich postgres"
  sensitive   = true
}
variable "minio_access_key_id" {
  sensitive = true
}

variable "minio_secret_access_key" {
  sensitive = true
}

variable "backblaze_key_id" {
  sensitive = true
}

variable "backblaze_app_key" {
  sensitive = true
}
