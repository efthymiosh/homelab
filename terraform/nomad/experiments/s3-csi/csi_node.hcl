job "s3-plugin" {
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
        image = "ctrox/csi-s3:v1.2.0-rc.1"
        privileged = true
        network_mode = "host"
        args = [
          "--endpoint=unix:///csi/csi.sock",
          "--nodeid=${node.unique.name}",
          "--v=4",
        ]
      }

      resources {
        cpu = 100
        memory = 40
      }

      csi_plugin {
        id        = "s3-csi"
        type      = "node"
        mount_dir = "/csi"
      }
    }
  }
}
