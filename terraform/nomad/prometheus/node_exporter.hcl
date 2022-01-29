variable "version" {
  default = "1.3.1"
}

job "node_exporter" {
  datacenters = ["homelab"]
  type = "system"

  group "node" {

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
