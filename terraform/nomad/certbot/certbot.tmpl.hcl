job "certbot_${domain}" {
  datacenters = ["homelab"]
  type = "batch"

  periodic {
    cron = "0 0 20 */2 *"
  }

  group "certbot" {
    count = 1

    restart {
      attempts = 0
      mode = "fail"
    }

    task "certbot" {
      driver = "docker"
      config {
        image = "docker-registry.efthymios.net/certbot-dns-cf-consul:latest"
      }
      env {
        CONSUL_HTTP_ADDR = "https://consul.efhd.dev"
        CF_CREDS_PATH    = "$${NOMAD_SECRETS_DIR}/cloudflare.ini"
        SSL_DOMAIN       = "${domain}"
      }
      template {
        env = true
        data = <<EOF
        CONTACT_EMAIL={{ key `ssl/contact_email` }}
        CONSUL_HTTP_TOKEN={{ with secret `kv/data/nomad/shared/consul_kv_write_token` }}{{ .Data.data.consul_kv_write_token }}{{ end }}
        EOF
        destination = "$${NOMAD_SECRETS_DIR}/.env"
      }
      template { 
        data = "dns_cloudflare_api_token = {{ key `ssl/cloudflare_api_token` }}"
        destination = "$${NOMAD_SECRETS_DIR}/cloudflare.ini"
        perms = "440"
      }
      resources {
        cpu = 500
        memory = 512
      }
    }
  }
}
