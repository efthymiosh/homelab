job "navidrome" {
  datacenters = ["homelab"]
  type        = "service"

  update {
    max_parallel     = 1
    min_healthy_time = "30s"
    healthy_deadline = "9m"
  }

  constraint {
    attribute = "${node.class}"
    operator  = "="
    value     = "mule"
  }

  group "navidrome" {
    count = 1

    restart {
      attempts = 3
      interval = "2m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      port "http" {
        to = 4533
      }
    }

    task "navidrome" {
      driver       = "docker"
      kill_timeout = "30s"
      config {
        image       = "deluan/navidrome:latest"
        privileged  = true
        force_pull  = true
        ports       = ["http"]
        mount {
          type   = "bind"
          source = "/mnt/data/navidrome"
          target = "/data"
          readonly = false
        }
        mount {
          type   = "bind"
          source = "/mnt/data/hoard/Music"
          target = "/music"
          readonly = true
        }
      }

      resources {
        cpu    = 500
        memory = 512
      }

      env {}

      service {
        name = "navidrome"
        tags = [
          "http",
          "routed",
        ]
        port = "http"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "30s"
          timeout  = "2s"
        }
      }
    }
  }
}
