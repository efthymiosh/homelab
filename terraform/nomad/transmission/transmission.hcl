job "transmission" {
  datacenters = ["homelab"]
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "30s"
    healthy_deadline = "9m"
  }

  constraint {
    attribute = "${node.class}"
    operator  = "="
    value     = "mule"
  }

  group "transmission" {
    count = 1

    restart {
      attempts = 3
      interval = "2m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "http"  {
        static = 9091
      }
    }

    task "transmission" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image = "lscr.io/linuxserver/transmission:latest"
        privileged = true
        network_mode = "host"
        mount {
          type = "bind"
          source = "/mnt/data/transmission"
          target = "/config"
          readonly = false
        }
        mount {
          type = "bind"
          source = "/mnt/data/Public"
          target = "/downloads"
          readonly = false
        }
      }
      resources {
        cpu = 500
        memory = 768
      }
      env {
        PUID = "0"
        PGID = "0"
        TZ = "Europe/Athens"
      }
      template {
        env = true
        data = <<EOF
        USER={{ key `/transmission/user` }}
        PASS={{ key `/transmission/pass` }}
        EOF
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }
      service {
        name = "transmission"
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
    }
  }
}
