locals {
  # Deployed models. Must match the `models` map
  active_model = "gemma4-26b"
  additional_active_models = ["gemma4-e2b", "gemma4-31b"]

  models = {
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
    "qwen-36-27b" = {
      model = "unsloth/Qwen3.6-27B-GGUF:UD-Q6_K_XL"
      extra_args = [
        "--ctx-size", "262144",
        "--temp", "0.6",
        "--top-p", "0.95",
        "--top-k", "20",
        "--min-p", "0.00",
        "--presence-penalty", "0.00",
        "--repeat-penalty", "1.0",
      ]
      memory = 26000
      memory_max = 44000
    }
    "gemma4-26b" = { # MoE 4B
      model = "unsloth/gemma-4-26B-A4B-it-GGUF:UD-Q8_K_XL"
      extra_args = [
        "--ctx-size", "131072",
        "--no-mmap", # bug ?
        "-fa", "off", # bug ?
        "--temp", "0.3",
        "--top-p", "0.95",
        "--top-k", "64",
        "--reasoning", "off",
      ]
      memory = 26000
      memory_max = 44000
    }
    "gemma4-31b" = {
      model = "unsloth/gemma-4-31B-it-GGUF:UD-Q6_K_XL"
      extra_args = [
        "--ctx-size", "131072",
        "--no-mmap", # bug ?
        "-fa", "off", # bug ?
        "--temp", "0.3",
        "--top-p", "0.95",
        "--top-k", "64",
        "--reasoning", "off",
      ]
      memory = 22000
      memory_max = 44000
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
    "--parallel", "2",
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
