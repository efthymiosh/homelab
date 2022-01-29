variable "conf" {
  description = "The vector configuration data"
}

job "vector" {
  datacenters = ["homelab"]
  type = "system"

  update {
    max_parallel = 0
  }

  group "vector" {
    count = 1

    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "http" {
        to = 8686
      }
    }

    ephemeral_disk {
      size = 500
      sticky = true
    }

    volume "vector" {
      type = "host"
      source = "docker-sock-ro"
      read_only = true
    }

    task "vector" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image = "timberio/vector:0.19.X-alpine"
        ports = ["http"]
      }

      volume_mount {
        volume = "vector"
        destination = "/var/run/docker.sock"
        read_only = true
      }

      env {
        VECTOR_CONFIG = "${NOMAD_TASK_DIR}/vector.toml"
      }

      template {
        data = var.conf
        destination = "${NOMAD_TASK_DIR}/vector.toml"
        change_mode = "signal"
        change_signal = "SIGHUP"
        left_delimiter = "[["
        right_delimiter = "]]"
      }
      resources {
        cpu = 400
        memory = 256
      }
      service {
        name = "vector"
        tags = ["http"]
        port = "http"
        check {
          type = "http"
          path = "/health"
          interval = "20s"
          timeout = "5s"
        }
      }
    }
  }
}
