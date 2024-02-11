job "ory_kratos" {
  datacenters = ["homelab"]
  type = "service"

  constraint {
    attribute = "${node.class}"
    operator  = "="
    value     = "snunmu"
  }

  group "server" {
    network {
      port "http" {
        to = 8080
      }
    }
    task "kratos" {
      driver = "docker"
      user = "root"
      config {
        image = "oryd/kratos:v1.0.0"
        ports = ["http"]
      }

      template {
        env = true
        data = <<EOF
        EOF
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }

      resources {
        cpu    = 250
        memory = 256
      }

      service {
        name = "ory-kratos"
        port = "http"

        check {
          type     = "tcp"
          interval = "15s"
          timeout  = "2s"
        }
      }
    }
  }
}
