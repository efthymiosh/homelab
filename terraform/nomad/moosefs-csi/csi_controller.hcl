job "moosefs-plugin-controller" {
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
        type      = "controller"
        mount_dir = "/csi"
      }
    }
  }
}
