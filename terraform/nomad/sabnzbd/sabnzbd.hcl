job "sabnzbd" {
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

  group "sabnzbd" {
    count = 1

    network {
      port "http"  {
        to = 8080
      }
    }

    task "sabnzbd" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image = "lscr.io/linuxserver/sabnzbd:latest"
        ports = ["http"]
        mount {
          type = "bind"
          source = "/mnt/data/sabnzbd"
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
      service {
        name = "sabnzbd"
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
