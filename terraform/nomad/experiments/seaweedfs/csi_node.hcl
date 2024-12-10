job "seaweedfs-plugin" {
  datacenters = ["homelab"]
  type = "system"

  constraint {
    operator = "distinct_hosts"
    value = true
  }

  group "node" {
    task "driver" {
      driver = "docker"
      kill_timeout = "30s"

      config {
        image = "chrislusf/seaweedfs-csi-driver@sha256:fc6a55cd609687ccc3df5765fbddb8742089e68546fa9ceed246bc4821b1955e"
        privileged = true
        args = [
          "--endpoint=unix:///csi/csi.sock",
          "--filer=${attr.unique.network.ip-address}:8888",
          "--nodeid=${node.unique.name}",
        ]
      }

      csi_plugin {
        id        = "seaweedfs-csi"
        type      = "node"
        mount_dir = "/csi"
      }
    }
  }
}
