variable "backup_script" {
}

job "consul_backup" {
  datacenters = ["homelab"]
  type = "batch"

  periodic {
    cron = "@daily"
  }

  constraint {
    attribute = "${node.class}"
    operator  = "="
    value     = "snunmu"
  }

  group "consul_backup" {
    count = 1

    restart {
      attempts = 0
      mode = "fail"
    }

    task "consul_backup" {
      driver = "docker"
      config {
        image = "docker-registry.efhd.dev/backups:latest"
        entrypoint = ["bash", "${NOMAD_ALLOC_DIR}/backup.sh"]
      }

      vault {}

      template {
        env = true
        data = <<EOF
        CONSUL_HTTP_ADDR="https://consul.efhd.dev"
        CONSUL_HTTP_TOKEN={{ with secret `kv/data/nomad/consul_backup` }}{{ .Data.data.token }}{{ end }}
        AWS_ACCESS_KEY_ID={{ key `backblaze/b2_app_key_id` }}
        AWS_SECRET_ACCESS_KEY={{ key `backblaze/b2_app_key` }}
        EOF
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }
      template {
        data = var.backup_script
        destination = "${NOMAD_ALLOC_DIR}/backup.sh"
      }
      resources {
        cpu = 500
        memory = 512
      }
    }
  }
}
