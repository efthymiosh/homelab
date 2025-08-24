job "paperless-ai" {
  datacenters = ["homelab"]
  type = "service"

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "aero1"
  }
  update {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "5m"
  }
  vault {}
  group "paperless-ai" {
    count = 1
    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }
    network {
      port "web" {
        to = 3000
      }
    }
    task "paperless-ai" {
      driver = "docker"
      config {
        image = "clusterzx/paperless-ai"
        ports = ["web"]
        mount {
          type = "volume"
          source = "paperless-ai"
          target = "/app/data"
          readonly = false
        }
      }
      template {
        env = true
        data = <<EOF
        PAPERLESS_NGX_URL = "https://paperless.efhd.dev"
        PAPERLESS_API_TOKEN = "{{ with secret `kv/data/nomad/shared/paperless` }}{{ .Data.data.admin_api_token }}{{ end }}"
        EOF
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }
      resources {
        cpu = 1024
        memory = 2048
      }
      service {
        name = "paperless-ai"
        tags = ["http", "routed"]
        port = "web"
        check {
          type = "tcp"
          interval = "20s"
          timeout = "5s"
        }
      }
    }
  }
}
