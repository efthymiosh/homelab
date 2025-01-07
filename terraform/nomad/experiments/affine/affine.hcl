locals {
  env = <<EOF
  PORT=3010
  NODE_ENV=production
  {{ with secret `kv/data/nomad/shared/postgresql` }}
  DATABASE_URL="postgresql://{{ .Data.data.user }}:{{ .Data.data.password }}@postgres.service.consul:5432/affine"
  {{ end }}
  AFFINE_SERVER_EXTERNAL_URL="https://affine.efhd.dev"
  DB_DATA_LOCATION="/data/postgres"
  UPLOAD_LOCATION="/data/storage"
  CONFIG_LOCATION="/data/config"
  REDIS_SERVER_HOST=redis-affine.service.consul
  EOF
}
job "affine" {
  datacenters = ["homelab"]
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "30s"
    healthy_deadline = "9m"
  }

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "sand"
  }

  group "affine" {
    count = 1

    vault {}

    network {
      port "http"  {
        to = 3010
      }
      port "redis" {
        static       = 6379
        to           = 6379
      }
    }

    task "affine" {
      driver = "docker"
      config {
        image = "ghcr.io/toeverything/affine-graphql:stable"
        force_pull = true
        ports = ["http"]
        mount {
          type = "volume"
          target = "/data"
          source = "affine_data"
        }
      }
      resources {
        cpu = 2000
        memory = 4096
      }
      template {
        env = true
        data = local.env
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }
      service {
        name = "affine"
        tags = [
          "http",
          "routed",
        ]
        port = "http"
        check {
          name = "alive"
          type = "tcp"
          interval = "30s"
          timeout  = "2s"
        }
      }
    }
    task "affine-migrations" {
      driver = "docker"
      lifecycle {
        hook = "prestart"
        sidecar = false
      }
      config {
        image = "ghcr.io/toeverything/affine-graphql:stable"
        force_pull = true
        entrypoint = ["sh", "-c", "node ./scripts/self-host-predeploy.js"]
        ports = ["http"]
      }
      resources {
        cpu = 500
        memory = 512
      }
      template {
        env = true
        data = local.env
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }
    }
    task "redis" {
      driver = "docker"
      config {
        image = "library/redis:7.2.4"
        ports = [ "redis" ]
      }
      resources {
        cpu = 10
        memory = 100
      }
      service {
        name = "redis-affine"
        port = "redis"
        check {
          name = "alive"
          type = "tcp"
          interval = "15s"
          timeout  = "2s"
        }
      }
    }
  }
}
