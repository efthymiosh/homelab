job "cloudflared" {
  datacenters = ["homelab"]
  type = "service"

  group "cloudflared" {
    count = 1

    restart {
      attempts = 3
      interval = "2m"
      delay = "25s"
      mode = "delay"
    }

    task "cloudflared" {
      driver = "docker"
      config {
        image = "cloudflare/cloudflared:latest"
        network_mode = "host"
        entrypoint = [ "cloudflared", "--no-autoupdate", "tunnel", "run", ]
      }
      resources {
        cpu = 500
        memory = 512
      }

      vault {}
      template {
        env = true
        data = <<EOF
        TUNNEL_TOKEN={{ with secret `kv/data/nomad/cloudflared` }}{{ .Data.data.token }}{{ end }}
        EOF
        destination = "$${NOMAD_SECRETS_DIR}/.env"
      }
    }
  }
}

