resource "nomad_external_volume" "prometheus" {
  type = "csi"

  plugin_id = "seaweedfs-csi"
  volume_id = "tsdb"
  name      = "tsdb"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  capacity_min = "40GiB"
  capacity_max = "40GiB"
}

resource "nomad_job" "prometheus" {
  jobspec = file("nomad/prometheus/prometheus.hcl")
  hcl2 {
    enabled = true
    vars = {
      volume = nomad_external_volume.prometheus.volume_id
      conf   = file("nomad/prometheus/prometheus.yml")
    }
  }
}
