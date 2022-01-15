variable "volume" {
  description = "The data volume for grafana"
}

job "grafana" {
  datacenters = ["homelab"]
  type = "service"

  group "grafana" {

    network {
      port "http"  {
        to = 3000
      }
    }

    volume "grafana_data" {
      type = "csi"
      source = var.volume
      attachment_mode = "file-system"
      access_mode = "single-node-writer"
    }

    task "grafana" {
      driver = "docker"
      config {
        image = "grafana/grafana:8.2.6"
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
        GF_SERVER_ENFORCE_DOMAIN = "true"
        GF_SERVER_ROOT_URL = "http://grafana.efthymios.net"
        GF_SNAPSHOTS_EXTERNAL_ENABLED = "false"
        GF_DASHBOARDS_MIN_REFRESH_INTERVAL = "15s"
        GF_USERS_ALLOW_SIGN_UP = "false"
        GF_ALERTING_ENABLED = "false"
        GF_LOG_LEVEL = "warn"
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
          interval = "30s"
          timeout  = "2s"
        }
      }
      volume_mount {
        volume = "grafana_data"
        destination = "/var/lib/grafana"
      }
    }
  }
}
