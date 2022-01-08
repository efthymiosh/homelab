job "tink" {
  datacenters = ["dc1"]
  type = "service"

  group "tink" {
    count = 1

    network {
      port  "grpc"  {
        static = 42113
      }
      port  "http"  {
        static = 42114
      }
    }

    task "apply-migrations" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }
      driver = "docker"
      config {
        image = "quay.io/tinkerbell/tink:latest"
        network_mode = "host"
      }
      env {
        ONLY_MIGRATION = "true"
        PGDATABASE = "tinkerbell"
        PGUSER = "tinkerbell"
        PGPASSWORD = "tinkerbell"
        PGSSLMODE = "disable"
        PGHOST = "localhost"
        PGPORT = "5432"
      }
    }

    task "tink" {
      driver = "docker"
      config {
        image = "quay.io/tinkerbell/tink:latest"
        network_mode = "host"
      }
      env {
        FACILITY = "homelab"
        PGDATABASE = "tinkerbell"
        PGUSER = "tinkerbell"
        PGPASSWORD = "tinkerbell"
        PGSSLMODE = "disable"
        PGHOST = "localhost"
        PGPORT = "5432"

        # expose the grpc and http endpoints on all interfaces
        TINKERBELL_GRPC_AUTHORITY = ":42113"
        TINKERBELL_HTTP_AUTHORITY = ":42114"

        TINKERBELL_CERTS_DIR = "${NOMAD_SECRETS_DIR}/certs/"
      }

      # at the time of writing CERTS_DIR expects this file to contain the ca public key
      template {
        data = file("ca.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/ca-crt.pem"
      }
      template {
        data = file("server-key.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/server-key.pem"
      }
      # at the time of writing CERTS_DIR expects these files to contain the public key
      template {
        data = file("server.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/server-crt.pem"
      }
      template {
        data = file("server.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/bundle.pem"
      }

      resources {
        cpu = 1000
        memory = 512
      }
    }
  }
}
