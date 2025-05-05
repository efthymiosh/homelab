variable "conf" {
  description = "The registry configuration file contents"
}

job "docker-registry" {
  datacenters = ["homelab"]
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "30s"
    healthy_deadline = "9m"
  }

  group "docker-registry" {
    count = 1

    restart {
      attempts = 3
      interval = "2m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "http"  {
        to = 5000
      }
      port "metrics" {
        to = 5001
      }
    }

    ephemeral_disk {
      migrate = true
      sticky  = true
      size    = 2000
    }

    task "docker-registry" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image = "registry:2"
        ports = ["http", "metrics"]
        mount {
          type = "bind"
          source = ".${NOMAD_SECRETS_DIR}/config.yml"
          target = "/etc/docker/registry/config.yml"
          readonly = false
        }
      }
      resources {
        cpu = 500
        memory = 2048
      }
      template {
        data = var.conf
        destination = "${NOMAD_SECRETS_DIR}/config.yml"
      }
      service {
        name = "docker-registry"
        tags = [
          "http",
          "routed",
        ]
        port = "http"
        check {
          name = "alive"
          type = "tcp"
          interval = "30s"
          timeout  = "2s"
        }
      }
      service {
        name = "docker-registry-metrics"
        tags = [
          "monitored",
          "prometheus.label.service=docker-registry",
        ]
        port = "metrics"
      }
    }
  }
}
