job "ghost" {
  datacenters = ["homelab"]
  type = "service"

  group "main" {
    network {
      port "http" {
        to = 2368
      }
    }

    ephemeral_disk {
      sticky  = true
      migrate = true
      size    = 1000
    }

    task "website" {
      driver = "docker"
      kill_timeout = "30s"

      config {
        image = "ghost:4.32"
        ports = ["http"]

        mount {
          type = "bind"
          source = "..${NOMAD_ALLOC_DIR}/data/"
          target = "/var/lib/ghost/content/"
          readonly = false
        }
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
        #url = "http://blog.efhd.me"
        url = "http://ghost.efthymios.net"
        admin = "http://ghost.efthymios.net"
        database__connection__filename = "${NOMAD_ALLOC_DIR}/data/ghost.db"
        logging__level = "info"
        logging__transports = "[\"stdout\"]"
        privacy__useTinfoil = "true"
      }
    }
  }
}
