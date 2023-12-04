locals {
  backup_targets = [
    "consul",
    "grafana",
    "immich",
    "ory",
  ]
}
resource "b2_bucket" "backups" {
  bucket_name = "efthymiosh-db-backups"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }

  dynamic "lifecycle_rules" {
    for_each = toset(local.backup_targets)
    content {
      file_name_prefix              = "${lifecycle_rules.key}/"
      days_from_uploading_to_hiding = 30
      days_from_hiding_to_deleting  = 1
    }
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

resource "consul_keys" "name" {
  key {
    path  = "backblaze/b2_app_key_id"
    value = b2_application_key.backups.application_key_id
  }
  key {
    path  = "backblaze/b2_app_key"
    value = b2_application_key.backups.application_key
  }
}

resource "nomad_job" "consul_backup" {
  jobspec = file("./nomad/consul-backup/consul_backup.hcl")
  hcl2 {
    vars = {
      backup_script = file("./nomad/consul-backup/backup.sh")
    }
  }
}

resource "nomad_job" "grafana_backup" {
  jobspec = file("./nomad/grafana/backup.hcl")
  hcl2 {
    vars = {
      backup_script = file("./nomad/grafana/backup.sh")
    }
  }
}

resource "nomad_job" "immich_backup" {
  jobspec = file("./nomad/immich/backup.hcl")
  hcl2 {
    vars = {
      backup_script = file("./nomad/immich/backup.sh")
    }
  }
}

resource "nomad_job" "ory_backup" {
  jobspec = file("./nomad/ory/backup.hcl")
  hcl2 {
    vars = {
      backup_script = file("./nomad/ory/resources/backup.sh")
    }
  }
}
