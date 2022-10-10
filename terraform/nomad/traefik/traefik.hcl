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
      port "metrics" {
        static = 8081
      }
      port "admin" {
        static = 8080
      }
    }

    task "traefik" {
      driver = "docker"
      config {
        image = "library/traefik:v2.9"
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
      service {
        name = "traefik-metrics"
        tags = [
          "http",
          "prometheus.label.service=traefik",
          "monitored",
        ]
        port = "metrics"
      }
      template {
        data = var.traefik_conf
        destination = "${NOMAD_TASK_DIR}/traefik.yaml"
      }
    }
  }
}
