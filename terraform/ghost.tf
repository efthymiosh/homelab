resource "nomad_external_volume" "ghost" {
  type = "csi"

  plugin_id = "s3-csi"
  volume_id = "ghost-content"
  name      = "ghost-content"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
  parameters = {
    mounter = "rclone"
  }
  secrets = {
    accessKeyID     = var.minio_access_key_id
    secretAccessKey = var.minio_secret_access_key
    endpoint        = "http://localhost:9000"
    region          = ""
  }

  capacity_min = "1GiB"
  capacity_max = "1GiB"
}

resource "nomad_job" "ghost" {
  jobspec = file("nomad/ghost/ghost.hcl")
  hcl2 {
    enabled = true
    vars = {
      volume = nomad_external_volume.ghost.volume_id
    }
  }
}
