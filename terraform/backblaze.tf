resource "b2_bucket" "backups" {
  bucket_name = "efthymiosh-db-backups"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }
}

resource "b2_application_key" "backups" {
  key_name  = "backups"
  bucket_id = b2_bucket.backups.bucket_id
  capabilities = [
    "listBuckets",
    "readBuckets",
    "listFiles",
    "readFiles",
    "writeFiles",
    "deleteFiles",
  ]
}
