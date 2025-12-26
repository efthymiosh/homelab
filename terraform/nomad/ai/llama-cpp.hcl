locals {
  # suggested setup for each model listed here
  models = {
    "unsloth/Devstral-Small-2" = {
      model = "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF:UD-Q4_K_XL",

    }

  }
}
job "llama-cpp" {
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
    healthy_deadline = "3m"
    progress_deadline = "5m"
  }

  group "llama-server" {
    count = 1

    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "http" {
        static = 8033
      }
    }

    task "llama-server" {
      driver = "raw_exec"
      user = "root"

      config {
        command = "llama-server"
        args = [
          "-hf", "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF:UD-Q4_K_XL",

          # Model alias (shows in WebUI)
          "--alias", "unsloth/Devstral-Small-2",

          "-ngl", "99",               # All layers to GPU (-1 = auto)
          "--parallel", "4",          # 4 parallel requests
          "--kv-unified",             # Unified KV cache (better for local use)
          "--threads", "-1",

          "--port", "8033",

          "--ctx-size", "16384",
          "--temp", "0.15",
          # Enable jinja for better chat template support
          "--jinja",

          # Flash attention (auto-detect)
          "-fa", "auto",

          # Enable endpoints
          "--metrics",                # Prometheus metrics
          "--props",                  # Property changes via POST
        ]
      }

      resources {
        cpu = 4096
        memory = 20480
        memory_max = 122880
      }

      service {
        name = "ai"
        tags = ["http", "routed"]
        port = "http"

        check {
          type = "http"
          path = "/health"
          interval = "20s"
          timeout = "5s"
        }
      }
    }
  }
}
