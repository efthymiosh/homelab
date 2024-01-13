variable "conf" {
  description = "The prometheus configuration"
}

job "prometheus" {
  datacenters = ["homelab"]
  type = "service"

  group "prometheus" {

    network {
      port "http"  {
        static = 9090
      }
    }

    ephemeral_disk {
      migrate = true
      size    = 5000
      sticky  = true
    }

    task "prometheus" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image = "prom/prometheus:v2.32.1"
        args = [
          "--storage.tsdb.retention.time=90d",
          "--config.file=/${NOMAD_TASK_DIR}/prometheus.yml",
          "--storage.tsdb.path=${NOMAD_ALLOC_DIR}/prometheus/",
        ]
        ports = ["http"]
      }
      resources {
        cpu = 3000
        memory = 2048
      }
      service {
        name = "prometheus"
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
      template {
        data = var.conf
        destination = "${NOMAD_TASK_DIR}/prometheus.yml"
      }
      template {
        data = "{{ key `ssl/root_ca_cert` }}"
        destination = "${NOMAD_TASK_DIR}/root-ca.pem"
      }
      template {
        data = "{{ key `ssl/interm_ca_cert` }}"
        destination = "${NOMAD_TASK_DIR}/interm-ca.pem"
      }
    }
  }
}
