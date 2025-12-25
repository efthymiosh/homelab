job "ollama" {
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

  group "ollama" {
    count = 1

    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "http" {
        static = 11434
      }
      port "web" {
        to = 8080
      }
    }

    task "ollama" {
      driver = "docker"
      user = "root"
      config {
        image = "ollama/ollama:rocm"
        force_pull =  true
        ports = ["http"]
        group_add = [ "video" ]
        privileged = true
        ipc_mode = "host"
        cap_add = [ "sys_ptrace" ]
        security_opt = [ "seccomp=unconfined" ] 
        mount {
          type = "bind"
          source = "/usr/share/ollama"
          target = "/root/"
          readonly = false
        }
      }
      env {
        HSA_OVERRIDE_GFX_VERSION = "11.5.1"
        OLLAMA_KEEP_ALIVE = "-1"
      }

      resources {
        cpu = 2048
        memory = 4096
      }
      service {
        name = "ollama-api"
        tags = ["http", "routed"]
        port = "http"
        check {
          type = "tcp"
          interval = "20s"
          timeout = "5s"
        }
      }
    }
    task "web_ui" {
      driver = "docker"
      config {
        image = "ghcr.io/open-webui/open-webui:main"
        force_pull =  true
        ports = ["web"]
        group_add = [ "video" ]
        privileged = true
        ipc_mode = "host"
        cap_add = [ "sys_ptrace" ]
        security_opt = [ "seccomp=unconfined" ] 
        mount {
          type = "volume"
          source = "open-webui"
          target = "/app/backend/data"
          readonly = false
        }
      }
      env {
        OLLAMA_BASE_URL = "http://${NOMAD_HOST_ADDR_http}"
      }

      resources {
        cpu = 2048
        memory = 4096
      }
      service {
        name = "ollama"
        tags = ["http", "routed"]
        port = "web"
        check {
          type = "tcp"
          interval = "20s"
          timeout = "5s"
        }
      }
    }
  }
}
