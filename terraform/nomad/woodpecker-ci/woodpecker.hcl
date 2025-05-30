variable "tag" {
  default = "v3.5"
}

job "woodpecker" {
  datacenters = ["homelab"]
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "30s"
    healthy_deadline = "9m"
  }

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "aero1"
  }

  group "woodpecker" {
    count = 1

    vault {}

    restart {
      attempts = 3
      interval = "2m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "http"  {
        to = 8000
      }
      port "internal"  {
        static = 9111
        to = 9000
      }
    }

    task "woodpecker-server" {

      driver = "docker"
      config {
        image = "woodpeckerci/woodpecker-server:${var.tag}"
        force_pull = true
        ports = [ "http", "internal" ]

        mount {
          type     = "bind"
          source   = "/mnt/nomad/woodpecker/"
          target   = "/var/lib/woodpecker/"
          readonly = false
        }
      }
      resources {
        cpu = 200
        memory = 256
      }
      template {
        env = true
        data = <<EOF
        WOODPECKER_OPEN=false
        WOODPECKER_HOST=https://woodpecker.efhd.dev
        WOODPECKER_AGENT_SECRET={{ key `/woodpecker/agent_secret` }}
        WOODPECKER_GITHUB=true
        WOODPECKER_GITHUB_CLIENT={{ key `/woodpecker/githubapp/client_id` }}
        WOODPECKER_GITHUB_SECRET={{ key `/woodpecker/githubapp/client_secret` }}
        WOODPECKER_REPO_OWNERS=efthymiosh
        WOODPECKER_ADMIN=efthymiosh
        WOODPECKER_DATABASE_DRIVER=postgres
        {{ with secret `kv/data/nomad/shared/postgresql` }}
        WOODPECKER_DATABASE_DATASOURCE="postgresql://{{ .Data.data.user }}:{{ .Data.data.password }}@postgres.service.consul:5432/woodpecker?sslmode=require"
        {{ end }}
        EOF
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }
      service {
        name = "woodpecker"
        tags = [
          "http",
          "routed",
        ]
        port = "http"
        check {
          name = "alive"
          type = "tcp"
          interval = "30s"
          timeout  = "2s"
        }
      }
    }
  }
  group "woodpecker-agent" {
    count = 1

    restart {
      attempts = 3
      interval = "2m"
      delay = "25s"
      mode = "delay"
    }

    task "woodpecker-agent" {
      driver = "docker"
      config {
        image = "woodpeckerci/woodpecker-agent:${var.tag}"
        force_pull = true
        mount {
          type = "bind"
          source = "/var/run/docker.sock"
          target = "/var/run/docker.sock"
          readonly = false
        }
      }
      resources {
        cpu = 200
        memory = 50
      }
      template {
        env = true
        data = <<EOF
        WOODPECKER_SERVER=woodpecker.service.consul:9111
        WOODPECKER_AGENT_SECRET={{ key `/woodpecker/agent_secret` }}
        WOODPECKER_AGENT_CONFIG_FILE={{ env `NOMAD_ALLOC_DIR` }}/agent.conf
        WOODPECKER_MAX_WORKFLOWS=8
        EOF
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }
    }
  }
}
