job "glusterfs-plugin-controller" {
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
        image = "docker.io/gluster/glusterfs-csi-driver"
        privileged = true
        args = [
          "--nodeid=controller",
          "--v=4",
          "--endpoint=unix:///csi/csi.sock",
          "--resturl=https://${attr.unique.network.ip-address}:24007",
          "--resttimeout=120",
        ]
      }

      csi_plugin {
        id        = "glusterfs-csi"
        type      = "controller"
        mount_dir = "/csi"
      }
    }
  }
}
