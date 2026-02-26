job "voice-agent" {
  datacenters = ["homelab"]
  type = "service"

  constraint {
    attribute = "${node.class}"
    operator  = "="
    value     = "jarvis"
  }

  update {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "5m"
  }

  group "voice-agent" {
    count = 1

    restart {
      attempts = 3
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      port "http" {}
    }

    task "agent" {
      driver = "docker"
      user   = "root"

      config {
        image      = "docker-registry.efhd.dev/homeagent:latest"
        force_pull = false
        ports      = ["http"]
        

        devices = [
          {
            host_path      = "/dev/snd"
            container_path = "/dev/snd"
          }
        ]

        mount {
          type     = "bind"
          source   = "/run/user/1000/pipewire-0"
          target   = "/tmp/pipewire/pipewire-0"
          readonly = false
        }
      }

      env {
        OPENAI_ENDPOINT       = "https://ai.efhd.dev/v1"
        OPENAI_MODEL          = "gpt-oss-120b"
        PIPEWIRE_RUNTIME_DIR  = "/tmp/pipewire"
        KOKORO_ONNX_PATH      = "/app/kokoro-v1.0.onnx"
        KOKORO_VOICES_PATH    = "/app/voices-v1.0.bin"
        TQDM_DISABLE          = "1"
      }

      resources {
        cpu    = 1024
        memory = 2048
      }
    }
  }
}
