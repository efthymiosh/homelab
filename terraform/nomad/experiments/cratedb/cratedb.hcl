job "cratedb" {
  datacenters = ["homelab"]
  type = "service"

  group "cratedb" {

    network {
      port "http"  {
        to = 4200
      }
    }

    task "cratedb" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image = "crate:5.8"
        args = [
          "crate",
          "-Cpath.conf=${NOMAD_TASK_DIR}",
        ]
        ports = ["http"]
      }
      env {
        CRATE_HEAP_SIZE = "512m"
      }
      resources {
        cpu = 1000
        memory = 1024
      }
      service {
        name = "cratedb"
        tags = [
          "http",
          "routed",
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
      vault {}
      template {
        destination = "${NOMAD_TASK_DIR}/crate.yml"
        data = <<EOF
        cluster.name: homelab
        node.name: cratedb-${NOMAD_ALLOC_INDEX}
        node.data: true
        network.host: _site_
        discovery.srv.query: cratedb.service.consul
        cluster.initial_master_nodes=cratedb-1,cratedb-2,cratedb-3
        gateway.expected_data_nodes=3
        gateway.recover_after_data_nodes=2
        EOF
      }
      template {
        data = "{{ key `ssl/root_ca_cert` }}"
        destination = "${NOMAD_TASK_DIR}/root-ca.pem"
      }
      template {
        data = <<EOF
        {{- with secret `pki/issue/nomad-workloads`
        `common_name=cratedb.service.consul`
        `ttl=7d`
        `alt_names=cratedb.service.homelab.dc.consul`
        -}}
        {{- .Data.certificate -}}
        {{- printf "\n" -}}
        {{- .Data.issuing_ca -}}
        {{- end -}}
        EOF
        destination = "${NOMAD_SECRETS_DIR}/cratedb.crt"
        change_mode = "noop"
      }
      template {
        data = <<EOF
        {{- with secret `pki/issue/nomad-workloads`
        `common_name=cratedb.service.consul`
        `ttl=7d`
        `alt_names=cratedb.service.homelab.dc.consul`
        -}}
        {{- .Data.private_key }}
        {{- end -}}
        EOF
        destination = "${NOMAD_SECRETS_DIR}/cratedb.key"
        change_mode = "noop"
      }
      template {
        data = "{{ key `ssl/root_ca_cert` }}"
        destination = "${NOMAD_SECRETS_DIR}/ca.crt"
      }
    }
  }
}
