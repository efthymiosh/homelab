variable "grafana_db" {
  description = "Grafana DB name"
  default = "grafana"
}
variable "grafana_user" {
  description = "Grafana DB username"
  default = "grafana"
}
variable "grafana_password" {
  description = "Grafana DB password"
}

job "grafana" {
  datacenters = ["homelab"]
  type = "service"

  group "grafana" {

    restart {
      mode     = "delay"
      interval = "1m"
      delay    = "15s"
    }

    network {
      port "http"  {
        to = 3000
      }
      port "db" {
        to = 3306
      }
    }

    task "grafana" {
      driver = "docker"
      config {
        image = "grafana/grafana:11.6.0"
        ports = ["http"]
      }
      resources {
        cpu = 100
        memory = 256
      }
      env {
        GF_ANALYTICS_CHECK_FOR_UPDATES = "false"
        GF_ANALYTICS_REPORTING_ENABLED = "false"
        GF_SERVER_ROUTER_LOGGING = "false"
        GF_SERVER_ENABLE_GZIP = "true"
        GF_SERVER_ROOT_URL = "http://grafana.efhd.dev"
        GF_SNAPSHOTS_EXTERNAL_ENABLED = "false"
        GF_DASHBOARDS_MIN_REFRESH_INTERVAL = "15s"
        GF_USERS_ALLOW_SIGN_UP = "false"
        GF_ALERTING_ENABLED = "false"
        GF_LOG_LEVEL = "warn"

        GF_DATABASE_TYPE = "postgres"
        GF_DATABASE_HOST = "postgresql-server.service.consul:5432"
        GF_DATABASE_NAME = var.grafana_db
        GF_DATABASE_USER = var.grafana_user
        GF_DATABASE_PASSWORD = var.grafana_password
      }
      service {
        name = "grafana"
        tags = [
          "http",
          "routed",
          "monitored",
        ]
        port = "http"
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
