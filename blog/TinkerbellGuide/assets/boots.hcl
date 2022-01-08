variable "tinkerbell_host_ip" {
  type = string
  default = "192.168.1.19"
}

variable "boots_host_ip" {
  type = string
  default = "192.168.1.19"
}

variable "assets_server_host_ip" {
  type = string
  default = "192.168.1.19"
}

variable "registry_host_ip" {
  type = string
  default = "192.168.1.19"
}

job "boots" {
  datacenters = ["dc1"]
  type = "service"

  group "boots" {
    count = 1

    network {
      port  "dhcp"  {
        static = 67
      }
      port  "tftp"  {
        static = 69
      }
      port "http" {
        static = 80
      }
      port "syslog" {
        static = 514
      }
    }

    task "boots" {
      driver = "docker"
      config {
        image = "quay.io/tinkerbell/boots:latest"
        args = [
          "-dhcp-addr", "0.0.0.0:67",
          "-tftp-addr", "${var.boots_host_ip}:69",
          "-http-addr", "${var.boots_host_ip}:80",
        ]
        cap_add = ["net_bind_service"]
        network_mode = "host"
      }
      env {
        FACILITY_CODE = "homelab"
        MIRROR_HOST = "${var.assets_server_host_ip}:8080"
        DNS_SERVERS = "1.1.1.1"
        PUBLIC_IP = "${var.boots_host_ip}"
        DOCKER_REGISTRY = "${var.registry_host_ip}:8443"
        REGISTRY_USERNAME = "admin"
        REGISTRY_PASSWORD = "admin"
        TINKERBELL_GRPC_AUTHORITY = "${var.tinkerbell_host_ip}:42113"
        TINKERBELL_CERT_URL = "http://${var.tinkerbell_host_ip}:42114/cert"
        DATA_MODEL_VERSION = "1"

        TINKERBELL_CERTS_DIR = "${NOMAD_SECRETS_DIR}/certs/"

        # legacy garbage?
        API_CONSUMER_TOKEN = "ignored"
        API_AUTH_TOKEN = "ignored"
      }

      template {
        data = file("ca.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/ca-crt.pem"
      }
      template {
        data = file("server-key.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/server-key.pem"
      }
      template {
        data = file("server.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/server-crt.pem"
      }
      template {
        data = file("server.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/bundle.pem"
      }

      resources {
        cpu = 1000
        memory = 512
      }
    }
  }
}
