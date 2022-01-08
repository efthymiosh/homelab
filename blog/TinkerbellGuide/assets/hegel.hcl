variable "tinkerbell_host_ip" {
  type = string
  default = "192.168.1.19"
}

job "hegel" {
  datacenters = ["dc1"]
  type = "service"

  group "hegel" {
    count = 1

    network {
      port "httpa" {
        static = 50060
      }
      port "httpb" {
        static = 50061
      }
      port "grpc" {
        static = 42115
      }
    }

    task "hegel" {
      driver = "docker"
      config {
        image = "quay.io/tinkerbell/hegel:latest"
        network_mode = "host"
      }
      env {
        GRPC_PORT = "42115"
        HEGEL_FACILITY = "homelab"
        HEGEL_USE_TLS = "0"
        TINKERBELL_GRPC_AUTHORITY = "${var.tinkerbell_host_ip}:42113"
        TINKERBELL_CERT_URL = "http://${var.tinkerbell_host_ip}:42114/cert"
        DATA_MODEL_VERSION = "1"
        CUSTOM_ENDPOINTS = "{\"/metadata\":\"\"}"
      }
      resources {
        cpu = 1000
        memory = 512
      }
    }
  }
}
