job "plex" {
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

  group "plex" {
    count = 1

    network {
      port "http"  {
        static = 32400
      }
    }

    ephemeral_disk {
      migrate = true
      sticky  = true
      size    = 2000
    }

    task "plex" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image = "lscr.io/linuxserver/plex:latest"
        ports = ["http"]
        network_mode = "host"
        mount {
          type = "bind"
          source = "/mnt/data/plex"
          target = "/config"
          readonly = false
        }
        mount {
          type = "bind"
          source = "/mnt/data/hoard"
          target = "/library"
          readonly = false
        }
        devices = [{
          host_path = "/dev/dri"
          container_path = "/dev/dri"
        }]
      }
      resources {
        cpu = 500
        memory = 2048
      }
      env {
        PUID = "0"
        PGID = "0"
      }
      service {
        name = "plex"
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

