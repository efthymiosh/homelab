variable "volume" {
  description = "The name of the volume to mount to ghost"
  type = string
}

job "ghost" {
  datacenters = ["homelab"]
  type = "service"

  group "main" {
    network {
      port "http" {
        to = 2368
      }
    }

    volume "ghost_content" {
      type = "csi"
      source = var.volume
      attachment_mode = "file-system"
      access_mode = "single-node-writer"
    }

    task "website" {
      driver = "docker"
      kill_timeout = "30s"

      config {
        image = "ghost:4.32"
        ports = ["http"]
      }

      service {
        name = "ghost"
        tags = ["http", "routed"]
        port = "http"
        check {
          name = "alive"
          type = "tcp"
          interval = "30s"
          timeout = "2s"
        }
      }

      resources {
        cpu = 500 # 500 Mhz
        memory = 512 # 512MB
      }

      env {
        url = "http://ghost.efthymios.net"
      }

      volume_mount {
        volume = "ghost_content"
        destination = "/var/lib/ghost/content"
      }
    }
  }
}
