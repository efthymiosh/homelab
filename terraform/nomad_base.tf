resource "nomad_scheduler_config" "config" {
  memory_oversubscription_enabled = false
  scheduler_algorithm             = "spread"
  preemption_config               = {
    batch_scheduler_enabled    = false
    service_scheduler_enabled  = false
    sysbatch_scheduler_enabled = false
    system_scheduler_enabled   = false
  }
}

resource "nomad_job" "traefik" {
  jobspec = file("nomad/traefik/traefik.hcl")
  hcl2 {
    enabled = true
    vars    = {
      traefik_conf = file("nomad/traefik/traefik.yaml")
    }
  }
}

resource "nomad_job" "etcd" {
  jobspec = file("nomad/etcd/etcd.hcl")
  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "seaweedfs" {
  jobspec = file("nomad/seaweedfs/filer.hcl")
  hcl2 {
    enabled = true
    vars    = {
      filer_conf = file("nomad/seaweedfs/filer.toml")
    }
  }
}

resource "nomad_job" "seaweedfs-csi-node" {
  jobspec = file("nomad/seaweedfs/csi_node.hcl")
  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "seaweedfs-csi-controller" {
  jobspec = file("nomad/seaweedfs/csi_controller.hcl")
  hcl2 {
    enabled = true
  }
}
