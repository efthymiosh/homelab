job "ory_keto" {
  datacenters = ["homelab"]
  type = "service"

  constraint {
    attribute = "${node.class}"
    operator  = "="
    value     = "snunmu"
  }

  group "ory_keto" {
    count = 1

    network {
      port "read" {
        static = 4456
      }
      port "write" {
        static = 4457
      }
      port "metrics" {
        to = 4468
      }
    }

    service {
      name = "ory-keto"
      port = "read"
    }

    dynamic "task" {
      for_each = {
        "ory-keto" = {
          args = ["serve", "--config", "${NOMAD_ALLOC_DIR}/config.yaml"]
          ports = ["read", "write", "metrics"]
        }
        "ory-keto-init-db" = {
          args = ["migrate", "up", "-y", "--config", "${NOMAD_ALLOC_DIR}/config.yaml"]
          ports = []
          prestart = true
        }
      }

      labels = ["${task.key}"]
      content {
        driver = "docker"
        config {
          image = "oryd/keto:v0.11.1-alpha.0"
          args = task.value.args
          ports = task.value.ports
        }
        dynamic "lifecycle" {
          for_each = lookup(task.value, "prestart", false) ? ["prestart"] : []
          content {
            hook = "prestart"
            sidecar = false
          }
        }
        resources {
          cpu = 200
          memory = 512
        }
        template {
          data = <<EOF
          dsn=postgres://{{ key `postgres/ory/user` }}:{{ key `postgres/ory/password` }}@postgresql-ory.service.consul:5432/keto?sslmode=disable
          EOF
          env = true
          destination = "${NOMAD_SECRETS_DIR}/.env"
        }
        template {
          data = <<EOF
          version: v0.8.0-alpha.2
          dsn: fromEnv
          namespaces:
            - id: 0
              name: access
          serve:
            metrics:
              port: 4468
              host: 0.0.0.0
            read:
              port: 4456
              host: 0.0.0.0
            write:
              port: 4457
              host: 0.0.0.0
          log:
            level: debug
          EOF
          destination = "${NOMAD_ALLOC_DIR}/config.yaml"
        }
      }
    }
  }
}
