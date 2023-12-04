variable "backup_script" {
}

job "ory_backup" {
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

  group "ory_backup" {
    count = 1

    restart {
      attempts = 0
      mode = "fail"
    }

    task "ory_backup" {
      driver = "docker"
      config {
        image = "docker-registry.efthymios.net/backups:latest"
        entrypoint = ["bash", "${NOMAD_ALLOC_DIR}/backup.sh"]
      }
      template {
        env = true
        data = <<EOF
        AWS_ACCESS_KEY_ID="{{ key `backblaze/b2_app_key_id` }}"
        AWS_SECRET_ACCESS_KEY="{{ key `backblaze/b2_app_key` }}"
        PGUSER="{{ key `postgres/ory/user` }}"
        PGPASSWORD="{{ key `postgres/ory/password` }}"
        PGHOST="postgresql-ory.service.consul"
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
