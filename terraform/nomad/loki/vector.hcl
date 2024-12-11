variable "conf" {
  description = "The vector configuration data"
}
variable "version" {
  default = "0.43.1"
}

job "vector" {
  datacenters = ["homelab"]
  type = "system"

  update {
    max_parallel = 0
  }

  group "vector" {

    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "http" {
        static = 8686
      }
    }

    ephemeral_disk {
      size = 500
      sticky = true
    }

    task "vector" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image = "timberio/vector:${var.version}-alpine"
        volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ]
        ports = ["http"]
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
        cpu = 200
        memory = 200
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
