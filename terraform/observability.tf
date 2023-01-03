resource "nomad_job" "prometheus" {
  jobspec = file("nomad/prometheus/prometheus.hcl")
  hcl2 {
    enabled = true
    vars = {
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

resource "nomad_job" "container_exporter" {
  jobspec = file("nomad/prometheus/container_exporter.hcl")
  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "grafana_postgres" {
  jobspec = file("nomad/grafana/postgres.hcl")
  hcl2 {
    enabled = true
    vars = {
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
      conf   = file("nomad/loki/config.yaml")
    }
  }
}
