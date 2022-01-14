variable "filer_conf" {
  description = "The filer configuration"
}

job "seaweedfs" {
  datacenters = ["homelab"]
  type = "system"

  group "seaweedfs" {
    task "filer" {
      driver = "docker"
      config {
        image = "chrislusf/seaweedfs:2.85"
        args = [
          "filer",
          "-ip=${attr.unique.network.ip-address}",
          "-port=8888",
          "-master=snu1.int.efth.eu:9333,snu2.int.efth.eu:9333,snu3.int.efth.eu:9333",
          "-metricsPort=9335",
        ]
        network_mode = "host"
        work_dir = "${NOMAD_TASK_DIR}"
      }
      resources {
        cpu = 200
        memory = 128
      }
      template {
        data = var.filer_conf
        destination = "${NOMAD_TASK_DIR}/filer.toml"
      }
    }
  }
}