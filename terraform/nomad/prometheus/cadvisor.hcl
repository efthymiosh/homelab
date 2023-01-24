job "cadvisor" {
  datacenters = ["homelab"]
  type = "system"

  group "cadvisor" {

    network {
      port "http"  {
        to = 8080
      }
    }

    task "cadvisor" {
      driver = "docker"
      config {
        image = "gcr.io/cadvisor/cadvisor:v0.46.0"
        args = [
          "--store_container_labels=false",
          "--whitelisted_container_labels=com.hashicorp.nomad.job_name,com.hashicorp.nomad.task_group_name,com.hashicorp.nomad.task_name",
          "--docker_only",
          "--disable_root_cgroup_stats",
          "--storage_duration=1m0s",
          "--enable_metrics=accelerator,cpu,cpuLoad,disk,diskIO,memory,network,oom_event,percpu"
        ]
        ports = ["http"]
        mount {
          type = "bind"
          source = "/"
          target = "/rootfs"
          readonly = true
        }
        mount {
          type = "bind"
          source = "/sys"
          target = "/sys"
          readonly = true
        }
        mount {
          type = "bind"
          source = "/var/lib/docker"
          target = "/var/lib/docker"
          readonly = true
        }
        mount {
          type = "bind"
          source = "/var/run"
          target = "/var/run"
          readonly = true
        }
        mount {
          type = "bind"
          source = "/dev/disk"
          target = "/dev/disk"
          readonly = true
        }
        mount {
          type = "bind"
          source = "/dev/kmsg"
          target = "/dev/kmsg"
          readonly = true
        }
      }
      resources {
        cpu = 50
        memory = 50
      }
      service {
        name = "cadvisor"
        tags = [
          "http",
          "monitored",
        ]
        port = "http"
        check {
          name = "alive"
          type = "tcp"
          interval = "30s"
          timeout  = "2s"
        }
      }
    }
  }
}
