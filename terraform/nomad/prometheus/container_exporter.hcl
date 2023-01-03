variable "version" {
  default = "1.3.1"
}

job "container_exporter" {
  datacenters = ["homelab"]
  type = "system"

  group "metrics" {

    network {
      port "http"  {
        to = 9104
      }
    }

    task "exporter" {
      driver = "docker"
      config {
        image = "prom/container-exporter:latest"
        ports = ["http"]
        mount {
          type = "bind"
          source = "/sys/fs/cgroup"
          target = "/cgroup"
        }
        mount {
          type = "bind"
          source = "/var/run/docker.sock"
          target = "/var/run/docker.sock"
        }
      }
      resources {
        cpu = 50
        memory = 75
      }
      service {
        name = "container-exporter"
        tags = [
          "http",
          "monitored",
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
