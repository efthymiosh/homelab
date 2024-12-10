job "s3-plugin-controller" {
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
        image = "ctrox/csi-s3:v1.2.0-rc.1"
        privileged = true
        network_mode = "host"
        args = [
          "--endpoint=unix:///csi/csi.sock",
          "--nodeid=controller",
          "--v=4",
        ]
      }

      resources {
        cpu = 100
        memory = 40
      }

      csi_plugin {
        id        = "s3-csi"
        type      = "controller"
        mount_dir = "/csi"
      }
    }
  }
}
