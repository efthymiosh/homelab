resource "nomad_external_volume" "ghost" {
  type = "csi"

  plugin_id = "moosefs-csi"
  volume_id = "ghost_content"
  name      = "ghost_content"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
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
