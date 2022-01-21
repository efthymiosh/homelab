resource "nomad_external_volume" "prometheus" {
  type = "csi"

  plugin_id = "moosefs-csi"
  volume_id = "tsdb"
  name      = "tsdb"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  capacity_min = "40GiB"
  capacity_max = "40GiB"
}

resource "nomad_external_volume" "grafana" {
  type = "csi"

  plugin_id = "moosefs-csi"
  volume_id = "grafana"
  name      = "grafana"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  capacity_min = "1GiB"
  capacity_max = "1GiB"
}

resource "nomad_external_volume" "loki" {
  type = "csi"

  plugin_id = "moosefs-csi"
  volume_id = "loki"
  name      = "loki"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  capacity_min = "16GiB"
  capacity_max = "16GiB"
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

resource "nomad_job" "node_exporter" {
  jobspec = file("nomad/prometheus/node_exporter.hcl")
  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "grafana_postgres" {
  jobspec = file("nomad/grafana/postgres.hcl")
  hcl2 {
    enabled = true
    vars = {
      volume = nomad_external_volume.grafana.volume_id
      grafana_user     = "grafana"
      grafana_db       = "grafana"
      grafana_password = var.grafana_password
    }
  }
}

resource "nomad_job" "grafana" {
  jobspec = file("nomad/grafana/grafana.hcl")
  hcl2 {
    enabled = true
    vars = {
      grafana_user     = "grafana"
      grafana_db       = "grafana"
      grafana_password = var.grafana_password
    }
  }
}

resource "nomad_job" "vector" {
  jobspec = file("nomad/loki/vector.hcl")
  hcl2 {
    enabled = true
    vars = {
      conf   = file("nomad/loki/vector.toml")
    }
  }
}

resource "nomad_job" "loki" {
  jobspec = file("nomad/loki/loki.hcl")
  hcl2 {
    enabled = true
    vars = {
      volume = nomad_external_volume.loki.volume_id
      conf   = file("nomad/loki/config.yaml")
    }
  }
}
