locals {
  # Modify this to one of the keys on the map
  active_model = "gpt-oss-120b"

  models = {
    "Devstral-Small-2" = {
      model = "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF:UD-Q4_K_XL",
      extra_args = [
        "--ctx-size", "16384",
        "--temp", "0.15",
      ]
    }
    "Devstral-2" = {
      model = "unsloth/Devstral-2-123B-Instruct-2512-GGUF:UD-Q2_K_XL",
      extra_args = [
        "--ctx-size", "16384",
        "--temp", "0.15",
      ]
    }
    "Nemotron-3-Nano" = {
      model = "unsloth/Nemotron-3-Nano-30B-A3B-GGUF:UD-Q4_K_XL"
      extra_args = [
        "--ctx-size", "32768",
        "--temp", "0.6",
        "--top-p", "0.95",
      ]
    }
    "gpt-oss-120b" = {
      model = "unsloth/gpt-oss-120b-GGUF:F16"
      extra_args = [
        "--ctx-size", "16384",
        "--chat-template-kwargs", "{\"reasoning_effort\": \"low\"}",
        "--n-gpu-layers", "99",
        "--temp", "1.0",
        "--min-p", "0.0",
        "--top-p", "1.0",
        "--top-k", "0.0",
      ]
    }
  }
  active_model_setup = local.models[local.active_model]

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
        args = concat([
          "-hf", local.active_model_setup.model,

          # Model alias (shows in WebUI)
          "--alias", local.active_model,

          "-ngl", "99",
          "--parallel", "4",
          "--kv-unified",
          "--threads", "-1",

          "--host", "${NOMAD_IP_http}",
          "--port", "${NOMAD_PORT_http}",

          # Enable jinja for better chat template support
          "--jinja",

          # Flash attention (auto-detect)
          "-fa", "auto",

          # Enable endpoints
          "--metrics",                # Prometheus metrics
          "--props",                  # Property changes via POST
        ], local.active_model_setup.extra_args)
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
