variable "conf" {
  description = "The loki configuration data"
}

job "loki" {
  datacenters = ["homelab"]
  type = "service"

  update {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "5m"
  }

  group "loki" {
    count = 1

    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "http" {
        static = 3100
      }
    }

    task "loki" {
      driver = "docker"
      user = "root"
      config {
        image = "grafana/loki:2.4.2"
        args = [ "-config.file", "${NOMAD_SECRETS_DIR}/config.yaml" ]
        ports = ["http"]
      }

      template {
        data = var.conf
        destination = "${NOMAD_SECRETS_DIR}/config.yaml"
      }
      resources {
        cpu = 512
        memory = 512
      }
      service {
        name = "loki"
        tags = ["http", "monitored"]
        port = "http"
        check {
          type = "http"
          path = "/ready"
          interval = "20s"
          timeout = "5s"
        }
      }
    }
  }
}
