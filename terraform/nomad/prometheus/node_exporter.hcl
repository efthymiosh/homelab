variable "version" {
  default = "1.3.1"
}

job "node_exporter" {
  datacenters = ["homelab"]
  type = "system"

  group "node" {

    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "http"  {
        static = 9100
      }
    }

    task "exporter" {
      driver = "raw_exec"
      config {
        command = "/opt/node_exporter-${var.version}.linux-amd64/node_exporter"
      }
      artifact {
        source = "https://github.com/prometheus/node_exporter/releases/download/v${var.version}/node_exporter-${var.version}.linux-amd64.tar.gz"
        destination = "/opt/"
      }
      resources {
        cpu = 50
        memory = 75
      }
      service {
        name = "node-exporter"
        tags = [
          "http",
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
    }
  }
}
