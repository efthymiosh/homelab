job "jackett" {
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

  group "jackett" {
    count = 1

    network {
      port "http"  {
        to = 9117
      }
    }

    task "jackett" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image = "lscr.io/linuxserver/jackett:latest"
        ports = ["http"]
        mount {
          type = "bind"
          source = "/mnt/data/jackett"
          target = "/config"
          readonly = false
        }
      }
      resources {
        cpu = 500
        memory = 1024
      }
      env {
        PUID = "1000"
        PGID = "1000"
        TZ = "Europe/Nicosia"
        AUTO_UPDATE = "false"
      }
      service {
        name = "jackett"
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
