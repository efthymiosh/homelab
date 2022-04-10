locals {
  version  = "1.15.2"
  version_web = "1.15.0"
}

variable "conf" {
  description = "The contents for the configuration of temporal"
  type        = string
}

job "temporal" {
  datacenters = ["homelab"]
  type = "service"

  group "temporal" {
    count = 1

    network {
      port "grpc" {
        to = 7233
      }
      port "http" {
        to = 8088
      }
    }

    task "web" {
      driver = "docker"
      kill_timeout = "30s"

      config {
        image   = "temporalio/web:${local.version_web}"
        ports   = ["http"]
      }

      env = {
        TEMPORAL_GRPC_ENDPOINT   = "${NOMAD_ADDR_grpc}"
        TEMPORAL_PERMIT_WRITE_API=true
      }
      resources {
        cpu    = 100
        memory = 512
      }
      service {
        name = "temporal"
        tags = ["http", "routed"]
        port = "http"

        check {
          type     = "tcp"
          interval = "15s"
          timeout  = "2s"
        }
      }
    }
    task "temporal" {
      driver = "docker"
      kill_timeout = "30s"

      config {
        image   = "temporalio/auto-setup:${local.version}"
        ports   = ["grpc"]
      }

      env = {
        CASSANDRA_SEEDS = "scylladb.service.consul"
        DYNAMIC_CONFIG_FILE_PATH = "${NOMAD_TASK_DIR}/temporal.yaml"
      }
      template {
        data        = var.conf
        destination = "${NOMAD_TASK_DIR}/temporal.yaml"
      }
      resources {
        cpu    = 100
        memory = 512
      }
    }
    task "cli" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image   = "temporalio/admin-tools:${local.version}"
        ports   = []
      }
      env {
        TEMPORAL_CLI_ADDRESS = "${NOMAD_ADDR_grpc}"
      }
      resources {
        cpu    = 100
        memory = 512
      }
    }
  }
}
