job "moosefs-plugin" {
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
        image = "quay.io/tuxera/moosefs-csi-plugin:0.0.4"
        privileged = true
        args = [
          "--endpoint=unix:///csi/csi.sock",
          "--topology=master:EP,chunk:EP",
          "--mfs-endpoint=snu1.int.efth.eu",
        ]
      }

      csi_plugin {
        id        = "moosefs-csi"
        type      = "node"
        mount_dir = "/csi"
      }
    }
  }
}
