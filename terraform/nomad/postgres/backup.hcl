variable "backup_script" {}

job "postgres_backup" {
  datacenters = ["homelab"]
  type = "batch"

  periodic {
    cron = "@daily"
  }

  group "postgres_backup" {
    count = 1

    restart {
      attempts = 0
      mode = "fail"
    }

    task "postgres_backup" {
      driver = "docker"
      config {
        image = "docker-registry.efhd.dev/backups:latest"
        entrypoint = ["bash", "${NOMAD_ALLOC_DIR}/backup.sh"]
      }
      vault {}
      template {
        env = true
        data = <<EOF
        AWS_ACCESS_KEY_ID="{{ key `backblaze/b2_app_key_id` }}"
        AWS_SECRET_ACCESS_KEY="{{ key `backblaze/b2_app_key` }}"
        {{ with secret `kv/data/nomad/shared/postgresql` }}
        PGUSER={{ .Data.data.user }}
        PGPASSWORD={{ .Data.data.password }}
        {{ end }}
        PGHOST="postgres.service.consul"
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
