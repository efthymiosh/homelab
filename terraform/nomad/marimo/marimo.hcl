job "marimo" {
  datacenters = ["homelab"]
  type = "service"

  constraint {
    attribute = "${node.class}"
    operator  = "="
    value     = "jarvis"
  }

  update {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "5m"
  }

  group "marimo" {
    count = 1

    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "http" {
        to = 8080
      }
    }

    task "ensure_dir_exists" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }
      driver = "raw_exec"
      config {
        command = "sh"
        args = ["-c", "mkdir -p /usr/share/marimo"]
      }
    }

    task "marimo" {
      driver = "docker"
      user = "root"
      config {
        image = "docker-registry.efhd.dev/marimo:latest"
        force_pull =  true
        ports = ["http"]
        privileged = true
        cap_add = [ "checkpoint_restore" ]
        mount {
          type = "bind"
          source = "/usr/share/marimo"
          target = "/root/"
          readonly = false
        }
      }
      env {
      }

      resources {
        cpu = 2048
        memory = 1024
      }
      service {
        name = "marimo"
        tags = ["http", "routed"]
        port = "http"
        check {
          type = "tcp"
          interval = "20s"
          timeout = "5s"
        }
      }
    }
  }
}
