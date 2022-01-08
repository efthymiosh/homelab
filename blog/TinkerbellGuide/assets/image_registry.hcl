variable "registry_host_ip" {
  type = string
  default = "192.168.1.19"
}

job "image_registry" {
  datacenters = ["dc1"]
  type = "service"

  group "image_registry" {
    count = 1

    network {
      port "http" {
        static = 8443
      }
    }

    task "image_registry" {
      driver = "docker"
      config {
        image = "registry:2.7.1"
        network_mode = "host"
        ports = [
          "http"
        ]
      }
      env {
        REGISTRY_HTTP_ADDR = "${var.registry_host_ip}:8443"
        REGISTRY_HTTP_TLS_CERTIFICATE = "${NOMAD_SECRETS_DIR}/certs/server-crt.pem"
        REGISTRY_HTTP_TLS_KEY = "${NOMAD_SECRETS_DIR}/certs/server-key.pem"
        REGISTRY_AUTH = "htpasswd"
        REGISTRY_AUTH_HTPASSWD_REALM = "Registry Realm"
        REGISTRY_AUTH_HTPASSWD_PATH = "${NOMAD_SECRETS_DIR}/htpasswd"
        REGISTRY_PROXY_REMOTEURL = "https://quay.io"
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
        # username/password: admin/admin
        data = "admin:$2y$05$kaG7ZpF0X.vSrhcRxee4e.bJUNaZGXOYZsjrrCPhj53INYzrRVJaK"
        destination = "${NOMAD_SECRETS_DIR}/htpasswd"
      }
      resources {
        cpu = 1000
        memory = 512
      }
    }
  }
}
