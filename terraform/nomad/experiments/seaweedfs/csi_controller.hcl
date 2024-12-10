job "seaweedfs-plugin-controller" {
  datacenters = ["homelab"]
  type = "service"

  update {
    # use forced updates instead of deployments, we never want more than 1 running
    max_parallel = 0
  }

  constraint {
    operator = "distinct_hosts"
    value = true
  }

  group "node" {
    count = 1

    task "driver" {
      driver = "docker"
      kill_timeout = "30s"

      config {
        image = "chrislusf/seaweedfs-csi-driver@sha256:fc6a55cd609687ccc3df5765fbddb8742089e68546fa9ceed246bc4821b1955e"
        privileged = true
        args = [
          "--endpoint=unix:///csi/csi.sock",
          "--filer=${attr.unique.network.ip-address}:8888",
          "--nodeid=controller",
        ]
      }

      csi_plugin {
        id        = "seaweedfs-csi"
        type      = "controller"
        mount_dir = "/csi"
      }
    }
  }
}
