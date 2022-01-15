variable "conf" {
  description = "The prometheus configuration"
}

variable "volume" {
  description = "The data volume for prometheus"
}

job "prometheus" {
  datacenters = ["homelab"]
  type = "service"

  group "prometheus" {

    network {
      port "http"  {
        to = 9090
      }
    }

    volume "tsdb" {
      type = "csi"
      source = var.volume
      attachment_mode = "file-system"
      access_mode = "single-node-writer"
    }

    task "prometheus" {
      driver = "docker"
      config {
        image = "prom/prometheus:v2.32.1"
        args = [
          "--storage.tsdb.retention.time=7d",
          "--config.file=/${NOMAD_TASK_DIR}/prometheus.yml",
          "--storage.tsdb.path=/var/lib/prometheus/",
        ]
        ports = ["http"]
      }
      resources {
        cpu = 3000
        memory = 2048
      }
      service {
        name = "prometheus"
        tags = [
          "http",
          "routed",
          "monitored",
        ]
        port = "http"
        check {
          name = "alive"
          type = "tcp"
          interval = "30s"
          timeout  = "2s"
        }
      }
      template {
        data = var.conf
        destination = "${NOMAD_TASK_DIR}/prometheus.yml"
      }
      volume_mount {
        volume = "tsdb"
        destination = "/var/lib/prometheus"
      }
    }
  }
}
