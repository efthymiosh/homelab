job "radarr" {
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

  group "radarr" {
    count = 1

    restart {
      attempts = 3
      interval = "2m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "http"  {
        to = 7878
      }
    }

    task "radarr" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image = "lscr.io/linuxserver/radarr:latest"
        privileged = true
        force_pull = true
        ports = ["http"]
        mount {
          type = "bind"
          source = "/mnt/data/radarr"
          target = "/config"
          readonly = false
        }
        mount {
          type = "bind"
          source = "/mnt/data"
          target = "/data"
          readonly = false
        }
      }
      resources {
        cpu = 500
        memory = 512
      }
      env {
        PUID = "0"
        PGID = "0"
        TZ = "Europe/Nicosia"
      }
      service {
        name = "radarr"
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
