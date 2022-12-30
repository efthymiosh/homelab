job "sonarr" {
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

  group "sonarr" {
    count = 1

    network {
      port "http"  {
        to = 8989
      }
    }

    task "sonarr" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image = "lscr.io/linuxserver/sonarr:latest"
        ports = ["http"]
        mount {
          type = "bind"
          source = "/mnt/data/sonarr"
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
        memory = 1024
      }
      env {
        PUID = "0"
        PGID = "0"
        TZ = "Europe/Nicosia"
      }
      service {
        name = "sonarr"
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
