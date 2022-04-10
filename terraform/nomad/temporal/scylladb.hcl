locals {
  data_dir = "/var/lib/scylla"
}

job "scylladb" {
  datacenters = ["homelab"]
  type = "service"

  group "scylladb" {
    count = 3

    constraint {
      operator = "distinct_hosts"
      value    = true
    }

    network {
      port "db" {
        static = 9042
      }
      port "intra-node" {
        static = 7000
      }
      port "tls-intra-node" {
        static = 7001
      }
      port "jmx" {
        static = 7199
      }
    }

    # FIXME: The 4.6.1 tag has a bug where the `/var/lib/scylla/data` dir
    # will be created with root permissions. This was manually modified
    # on the running container for brevity, but a separate container
    # should pre-create the directories with the proper uid/gid
    ephemeral_disk {
      sticky  = true
      migrate = true
      size    = 1000
    }

    task "node" {
      driver = "docker"
      kill_timeout = "30s"

      config {
        image   = "scylladb/scylla:4.6.1"
        ports   = ["db", "intra-node", "tls-intra-node", "jmx"]
        args    = [
          "--seeds", "snu1.int.efth.eu,snu2.int.efth.eu,snu3.int.efth.eu",
          "--smp", "1",
          "--api-address", "0.0.0.0",
          "--listen-address", "0.0.0.0",
          "--broadcast-address", "${attr.unique.network.ip-address}",
          "--broadcast-rpc-address", "${attr.unique.network.ip-address}",
        ]
        privileged = true
        volumes = ["local/:${local.data_dir}"]
      }

      env = {
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      service {
        name = "scylladb"
        port = "db"

        check {
          type     = "tcp"
          interval = "15s"
          timeout  = "2s"
        }
      }
    }
  }
}
