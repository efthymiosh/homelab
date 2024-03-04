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
      driver = "docker"
      config {
        image = "prom/node-exporter:v1.7.0"
        ports = ["http"]
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
