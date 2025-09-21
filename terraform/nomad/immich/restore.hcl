variable "restore_script" {
}

job "immich_restore" {
  datacenters = ["homelab"]
  type = "batch"

  parameterized {
    payload = "required"
    meta_required = ["date"]
  }

  constraint {
    attribute = "${node.class}"
    operator  = "="
    value     = "snunmu"
  }

  group "immich_restore" {
    count = 1

    restart {
      attempts = 0
      mode = "fail"
    }

    task "immich_restore" {
      driver = "docker"
      config {
        image = "docker-registry.efhd.dev/backups:latest"
        entrypoint = ["bash", "${NOMAD_ALLOC_DIR}/restore.sh"]
      }
      template {
        env = true
        data = <<EOF
        AWS_ACCESS_KEY_ID="{{ key `backblaze/b2_app_key_id` }}"
        AWS_SECRET_ACCESS_KEY="{{ key `backblaze/b2_app_key` }}"
        PGUSER="{{ key `postgres/immich/user` }}"
        PGPASSWORD="{{ key `postgres/immich/password` }}"
        PGHOST="postgresql-immich.service.consul"
        EOF
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }
      template {
        data = var.restore_script
        destination = "${NOMAD_ALLOC_DIR}/restore.sh"
      }
      resources {
        cpu = 500
        memory = 512
      }
    }
  }
}
