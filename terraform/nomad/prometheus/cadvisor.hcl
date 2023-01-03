variable "version" {
  default = "1.3.1"
}

job "cadvisor" {
  datacenters = ["homelab"]
  type = "system"

  group "cadvisor" {

    network {
      port "http"  {
        to = 8080
      }
    }

    task "cadvisor" {
      driver = "docker"
      config {
        image = "gcr.io/cadvisor/cadvisor:v0.46.0"
        ports = ["http"]
        mount {
          type = "bind"
          source = "/"
          target = "/rootfs"
          readonly = true
        }
        mount {
          type = "bind"
          source = "/sys"
          target = "/sys"
          readonly = true
        }
        mount {
          type = "bind"
          source = "/var/lib/docker"
          target = "/var/lib/docker"
          readonly = true
        }
        mount {
          type = "bind"
          source = "/var/run"
          target = "/var/run"
          readonly = true
        }
        mount {
          type = "bind"
          source = "/dev/disk"
          target = "/dev/disk"
          readonly = true
        }
      }
      resources {
        cpu = 50
        memory = 75
      }
      service {
        name = "cadvisor"
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
