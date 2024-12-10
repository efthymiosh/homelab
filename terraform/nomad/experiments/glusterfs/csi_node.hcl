job "glusterfs-plugin" {
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
        image = "docker.io/gluster/glusterfs-csi-driver"
        privileged = true
        args = [
          "--nodeid=${node.unique.name}",
          "--v=4",
          "--endpoint=unix:///csi/csi.sock",
          "--resturl=https://${attr.unique.network.ip-address}:24007",
          "--resttimeout=120",
        ]
      }

      csi_plugin {
        id        = "glusterfs-csi"
        type      = "node"
        mount_dir = "/csi"
      }
    }
  }
}
