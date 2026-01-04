job "lemonade" {
  datacenters = ["homelab"]
  type = "service"

  constraint {
    attribute = "${node.class}"
    operator  = "="
    value     = "jarvis"
  }

  update {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "30m"
    progress_deadline = "35m"
  }

  group "lemonade-server" {
    count = 1

    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "http" {
        static = 8044
      }
    }

    task "lemonade-server" {
      driver = "raw_exec"
      user = "root"

      config {
        command = "lemonade-server"
        args = [
          "serve",
          "--llamaccp", "rocm",
          "--log-level", "info",
          "--host", "${NOMAD_IP_http}",
          "--port", "${NOMAD_PORT_http}",
        ]
      }

      resources {
        cpu = 4096
        memory = 20480
        memory_max = 122880
      }

      service {
        name = "lnai"
        tags = ["http", "routed"]
        port = "http"
      }
    }
  }
}
