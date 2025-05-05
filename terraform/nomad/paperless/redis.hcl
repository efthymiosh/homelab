job "redis-paperless" {
  datacenters = ["homelab"]
  type = "service"

  group "redis-paperless" {
    count = 1

    restart {
      attempts = 3
      interval = "2m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "redis" {
        static       = 6379
        to           = 6379
      }
    }
    task "redis-master" {
      driver = "docker"
      config {
        image = "library/redis:7.2.4"
        args =  [
          "redis-server",
          "${NOMAD_ALLOC_DIR}/redis.conf",
          "--loglevel", "warning",
        ]
        ports = [ "redis" ]
      }
      resources {
        cpu = 10
        memory = 100
      }
      service {
        name = "redis-paperless"
        port = "redis"
        check {
          name = "alive"
          type = "tcp"
          interval = "15s"
          timeout  = "2s"
        }
      }
      vault {}
      template {
        destination = "${NOMAD_ALLOC_DIR}/redis.conf"
        change_mode = "signal"
        change_signal = "SIGINT"
        data = <<EOF
          maxmemory 0
          min-slaves-max-lag 5
          min-slaves-to-write 0
          rdbchecksum yes
          rdbcompression yes
          repl-diskless-sync yes
          port 0
          tls-port 6379
          tls-cert-file /secrets/redis.crt
          tls-key-file /secrets/redis.key
          tls-ca-cert-file /secrets/ca.crt
          tls-auth-clients no
        EOF
      }
      template {
        data = <<EOF
        {{- with secret `pki/issue/nomad-workloads`
        `common_name=redis-paperless.service.consul`
        `ttl=7d`
        `alt_names=redis-paperless.service.homelab.dc.consul`
        -}}
        {{- .Data.certificate -}}
        {{- printf "\n" -}}
        {{- .Data.issuing_ca -}}
        {{- end -}}
        EOF
        destination = "${NOMAD_SECRETS_DIR}/redis.crt"
        change_mode = "script"
        change_script {
          command = "redis-cli"
          args = ["config", "set", "tls-cert-file", "/secrets/redis.crt"]
        }
        uid   = 999
        perms = "600"
      }
      template {
        data = <<EOF
        {{- with secret `pki/issue/nomad-workloads`
        `common_name=redis-paperless.service.consul`
        `ttl=7d`
        `alt_names=redis-paperless.service.homelab.dc.consul`
        -}}
        {{- .Data.private_key }}
        {{- end -}}
        EOF
        destination = "${NOMAD_SECRETS_DIR}/redis.key"
        change_mode = "script"
        change_script {
          command = "redis-cli"
          args = ["config", "set", "tls-key-file", "/secrets/redis.key"]
        }
        uid   = 999
        perms = "600"
      }
      template {
        data = "{{ key `ssl/root_ca_cert` }}"
        destination = "${NOMAD_SECRETS_DIR}/ca.crt"
      }
    }
  }
}
