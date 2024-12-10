job "etcd" {
  datacenters = ["homelab"]
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "30s"
    healthy_deadline = "9m"
  }

  group "etcd" {
    count = 3

    network {
      port "peer"  {
        to = 2380
      }
      port "client"  {
        to = 2379
      }
    }

    ephemeral_disk {
      migrate = true
      sticky  = true
      size    = 300
    }

    # group services register before any tasks is running; needed for etcd discovery
    service {
      name = "etcd-server"
      port = "peer"
    }

    task "etcd" {
      driver = "docker"
      kill_timeout = "30s"
      config {
        image = "gcr.io/etcd-development/etcd:v3.5.1-amd64"
        args = [
          "/usr/local/bin/etcd",
          "--name=node${NOMAD_ALLOC_INDEX}",
          "--discovery-srv=service.consul",
          "--initial-advertise-peer-urls=http://${NOMAD_ADDR_peer}",
          "--initial-cluster-token=seaweedfs",
          "--initial-cluster-state=new",
          "--advertise-client-urls=http://${NOMAD_ADDR_client}",
          "--listen-client-urls=http://0.0.0.0:2379",
          "--listen-peer-urls=http://0.0.0.0:2380",
        ]
        ports = ["peer", "client"]
      }
      resources {
        cpu = 500
        memory = 512
      }
      service {
        name = "etcd"
        tags = [
          "http",
          "monitored",
        ]
        port = "client"
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
