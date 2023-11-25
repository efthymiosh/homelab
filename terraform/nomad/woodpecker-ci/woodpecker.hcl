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
    operator  = "="
    value     = "snu3"
  }

  group "woodpecker" {
    count = 1

    network {
      port "http"  {
        to = 8000
      }
      port "internal"  {
        to = 9000
      }
    }

    task "woodpecker-server" {
      driver = "docker"
      config {
        image = "woodpeckerci/woodpecker-server:latest"
        ports = [ "http", "internal" ]
        volumes = [
          "woodpecker-server-data:/var/lib/woodpecker"
        ]
      }
      resources {
        cpu = 200
        memory = 256
      }
      template {
        env = true
        data = <<EOF
        WOODPECKER_OPEN=true
        WOODPECKER_HOST=https://woodpecker.efhd.dev
        WOODPECKER_AGENT_SECRET={{ key `/woodpecker/agent_secret` }}
        WOODPECKER_GITHUB=true
        WOODPECKER_GITHUB_CLIENT={{ key `/woodpecker/githubapp/client_id` }}
        WOODPECKER_GITHUB_SECRET={{ key `/woodpecker/githubapp/client_secret` }}
        WOODPECKER_REPO_OWNERS=efthymiosh
        WOODPECKER_ADMIN=efthymiosh
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
    task "woodpecker-agent" {
      driver = "docker"
      config {
        image = "woodpeckerci/woodpecker-agent:latest"
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
        WOODPECKER_SERVER={{ env `NOMAD_ADDR_internal` }}
        WOODPECKER_AGENT_SECRET={{ key `/woodpecker/agent_secret` }}
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
}
