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
      driver = "docker"
      user = "root"

      config {
        image = "ghcr.io/ggml-org/llama.cpp:server-vulkan"
        force_pull = false
        ports = ["http"]

        # GPU access for Vulkan
        devices = [
          {
            host_path = "/dev/dri"
            container_path = "/dev/dri"
          }
        ]

        group_add = ["video"]
        privileged = false

        # Mount for model storage
        mount {
          type = "bind"
          source = "/usr/share/llama-models"
          target = "/root"
          readonly = false
        }

        # Command to start llama-server with your model
        # Adjust the model path and parameters as needed
        args = [
          "-hf", "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF:UD-Q4_K_XL",

          # Model alias (shows in WebUI)
          "--alias", "unsloth/Devstral-Small-2",

          "-c", "32768",              # Context size (32k)
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

      env {
        VK_ICD_FILENAMES = "/usr/share/vulkan/icd.d/radeon_icd.x86_64.json"
        RADV_PERFTEST = "nggc,sam"
        AMD_VULKAN_ICD = "RADV"
        RADV_DEBUG = ""
        GGML_VULKAN_DEVICE = "0"
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
