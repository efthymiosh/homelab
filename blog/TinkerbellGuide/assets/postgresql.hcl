job "postgres" {
  datacenters = ["dc1"]
  type = "service"

  group "postgres" {
    count = 1

    network {
      port  "db"  {
        static = 5432
      }
    }

    task "postgres" {
      driver = "docker"
      config {
        image = "postgres:14-alpine"
        network_mode = "host"
        mount {
          type = "bind"
          target = "/var/lib/postgresql/data"
          source = "/var/lib/nomad/postgresql"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }
      }
      env {
        POSTGRES_DB="tinkerbell"
        POSTGRES_USER="tinkerbell"
        POSTGRES_PASSWORD="tinkerbell"
      }

      resources {
        cpu = 1000
        memory = 512
      }
    }
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

  }

  update {
    max_parallel = 1
    min_healthy_time = "5s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }
}

