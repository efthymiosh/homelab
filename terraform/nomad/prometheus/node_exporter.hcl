job "node_exporter" {
  datacenters = ["homelab"]
  type = "system"

  group "node" {

    network {
      port "http"  {
        to = 9100
      }
    }

    task "exporter" {
      driver = "docker"
      config {
        image = "prom/node-exporter:v1.3.1"
        ports = ["http"]
      }
      resources {
        cpu = 400
        memory = 256
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
