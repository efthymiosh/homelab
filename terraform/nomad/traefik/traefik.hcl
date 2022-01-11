variable "traefik_conf" {
  description = "The traefik configuration"
}

job "traefik" {
  datacenters = ["homelab"]
  type = "system"

  group "traefik" {

    network {
      port "http"  {
        static = 80
      }
      port "https"  {
        static = 443
      }
      port "admin" {
        static = 8080
      }
    }

    task "traefik" {
      driver = "docker"
      config {
        image = "library/traefik:v2.5"
        args = ["--configFile=${NOMAD_TASK_DIR}/traefik.yaml"]
        cap_add = ["net_bind_service"]
        network_mode = "host"
        ports = ["http", "https", "admin"]
      }
      resources {
        cpu = 500
        memory = 128
      }
      service {
        name = "traefik"
        tags = [
          "http",
          "routed",
        ]
        port = "admin"
        check {
          name = "alive"
          type = "tcp"
          interval = "30s"
          timeout  = "2s"
        }
      }
      template {
        data = var.traefik_conf
        destination = "${NOMAD_TASK_DIR}/traefik.yaml"
      }
    }
  }
}
