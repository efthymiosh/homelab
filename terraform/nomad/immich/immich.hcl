variable "immich_pass" {
  description = "immich DB password"
}

job "immich" {
  datacenters = ["homelab"]
  type = "service"

  constraint {
    attribute = "${attr.unique.hostname}"
    value = "mule"
  }

  group "immich" {
    count = 1

    network {
      port "http" {
        to = 8080
      }
    }
    task "immich" {
      driver = "docker"
      config {
        image = "ghcr.io/imagegenius/immich:latest"
        mount {
          type     = "bind"
          target   = "/config"
          source   = "/mnt/data/immich/"
          readonly = false
        }

        mount {
          type     = "bind"
          target   = "/photos"
          source   = "/mnt/data/hoard/Pictures/Immich"
          readonly = false
        }

        ports = ["http"]
      }
      env {
        PUID = "0"
        PGID = "0"
        TZ   = "Europe/Nicosia"
        DB_HOSTNAME = "postgresql-immich.service.consul"
        DB_USERNAME = "immich"
        DB_PASSWORD = var.immich_pass
        DB_DATABASE_NAME = "immich"
        REDIS_HOSTNAME = "redis-immich.service.consul"
        DISABLE_MACHINE_LEARNING = "false"
        DISABLE_TYPESENSE = "false"
        DB_PORT = "5432"
        REDIS_PORT = "6379"
        MACHINE_LEARNING_WORKERS = "1"
        MACHINE_LEARNING_WORKER_TIMEOUT = "120"
      }
      resources {
        cpu = 400
        memory = 2048
      }
      service {
        name = "immich"
        tags = ["http", "routed"]
        port = "http"
      }
    }
  }
}
