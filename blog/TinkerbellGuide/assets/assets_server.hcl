
job "assets_server" {
  datacenters = ["dc1"]
  type = "service"

  group "assets_server" {
    count = 1

    ephemeral_disk {
      size    = 4000
      migrate = false
      sticky  = false
    }

    network {
      port  "http"  {
        to = 80
        static = 8080
      }
    }

    task "load_osie" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }
      driver = "docker"
      config {
        image = "bash:4.4"
        command = "bash"
        args = [
          "${NOMAD_TASK_DIR}/lastmile.sh",
          "https://github.com/tinkerbell/hook/releases/download/5.10.57/hook_x86_64.tar.gz,https://github.com/tinkerbell/hook/releases/download/5.10.57/hook_aarch64.tar.gz",
          #"https://tinkerbell-oss.s3.amazonaws.com/osie-uploads/osie-1790-23d78ea47f794d0e5c934b604579c26e5fce97f5.tar.gz",
          "/usr/share/nginx/html/misc/osie/current",
          "/usr/share/nginx/html/misc/osie/current",
          "/usr/share/nginx/html/workflow",
          "true",
          #"false",
        ]
        mount {
          type = "bind"
          target = "/usr/share/nginx/html/"
          source = "/var/lib/nomad/os_images/"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }
      }
      template {
        data = file("scripts/lastmile.sh")
        destination = "${NOMAD_TASK_DIR}/lastmile.sh"
      }
    }
    task "assets_server" {
      driver = "docker"
      config {
        image = "nginx:1.21.5-alpine"
        network_mode = "bridge"
        mount {
          type = "bind"
          target = "/usr/share/nginx/html/"
          source = "/var/lib/nomad/os_images/"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }
        ports = [
          "http"
        ]
      }
      resources {
        cpu = 1000
        memory = 512
      }
    }
  }
}
