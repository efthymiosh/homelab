locals {
  # Deployed models. Must match the `models` map
  active_model = "gemma4-26b"
  additional_active_models = ["gemma4-31b", "gemma4-e2b"]

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
    "gpt-oss-120b" = { # MoE 5.5B
      model = "unsloth/gpt-oss-120b-GGUF:F16"
      extra_args = [
        "--ctx-size", "262114",
        "--chat-template-kwargs", <<EOF
        { "reasoning_effort": "low"}
        EOF
        ,
        "--n-gpu-layers", "99",
        "--temp", "1.0",
        "--min-p", "0.0",
        "--top-p", "1.0",
        "--top-k", "0.0",
      ]
    }
    "qwen3-vl-32b" = {
      model  = "unsloth/Qwen3-VL-32B-Instruct-GGUF:UD-Q4_K_XL"
      extra_args = [
        "--ctx-size", "8192",
        "--n-gpu-layers", "99",
        "--temp", "0.7",
        "--min-p", "0.0",
        "--top-p", "0.8",
        "--top-k", "20",
        "--presence-penalty", "1.5",
      ]
    }
    "gemma4-26b" = { # MoE 4B
      model = "unsloth/gemma-4-26B-A4B-it-GGUF:UD-Q4_K_XL"
      extra_args = [
        "--ctx-size", "262144",
        "--temp", "0.3",
        "--top-p", "0.95",
        "--top-k", "64",
        "--reasoning", "off",
      ]
      memory = 16000
      memory_max = 22000
    }
    "gemma4-31b" = {
      model = "unsloth/gemma-4-31B-it-GGUF:UD-Q4_K_XL"
      extra_args = [
        "--ctx-size", "262144",
        "--temp", "0.3",
        "--top-p", "0.95",
        "--top-k", "64",
        "--reasoning", "off",
      ]
      memory = 22000
      memory_max = 34000
    }
    "gemma4-e4b" = {
      model = "unsloth/gemma-4-E4B-it-GGUF:UD-Q4_K_XL"
      extra_args = [
        "--ctx-size", "131072",
        "--temp", "1.0",
        "--top-p", "0.95",
        "--top-k", "64",
        "--reasoning", "off",
      ]
      memory = 6000
      memory_max = 14000
    }
    "gemma4-e2b" = {
      model = "unsloth/gemma-4-E2B-it-GGUF:UD-Q4_K_XL"
      extra_args = [
        "--ctx-size", "131072",
        "--temp", "1.0",
        "--top-p", "0.95",
        "--top-k", "64",
        "--reasoning", "off",
      ]
      memory = 3000
      memory_max = 7000
    }
  }
  base_llama_server_args = [

    "-ngl", "99",
    "--parallel", "4",
    "--kv-unified",
    "--threads", "-1",

    # Enable jinja for better chat template support
    "--jinja",

    # Flash attention (auto-detect)
    "-fa", "auto",

    # Enable endpoints
    "--metrics",                # Prometheus metrics
    "--props",                  # Property changes via POST
  ]
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
    healthy_deadline = "30m"
    progress_deadline = "35m"
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
        args = concat(
          [
            "-hf", local.models[local.active_model].model,
            # Model alias (shows in WebUI)
            "--alias", local.active_model,
            "--host", "${NOMAD_IP_http}",
            "--port", "${NOMAD_PORT_http}",
          ],
          local.base_llama_server_args,
          local.models[local.active_model].extra_args
        )
      }

      resources {
        cpu = 1024
        memory = local.models[local.active_model].memory
        memory_max = local.models[local.active_model].memory_max
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
  dynamic "group" {
    labels = [group.value]
    for_each = local.additional_active_models
    content {
      count = 1

      restart {
        attempts = 3
        interval = "5m"
        delay = "25s"
        mode = "delay"
      }

      network {
        port "http" {}
      }

      task "llama-server" {
        driver = "raw_exec"
        user = "root"

        config {
          command = "llama-server"
          args = concat(
            [
              "-hf", local.models[group.value].model,
              # Model alias (shows in WebUI)
              "--alias", group.value,
              "--host", "${NOMAD_IP_http}",
              "--port", "${NOMAD_PORT_http}",
            ],
            local.base_llama_server_args,
            local.models[group.value].extra_args
          )
        }

        resources {
          cpu = 1024
          memory = local.models[group.value].memory
          memory_max = local.models[group.value].memory_max
        }

        service {
          name = "ai-${group.value}"
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
}
