resource "nomad_scheduler_config" "config" {
  memory_oversubscription_enabled = true
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

resource "nomad_job" "s3-csi-node" {
  jobspec = file("nomad/s3-csi/csi_node.hcl")
  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "s3-csi-controller" {
  jobspec = file("nomad/s3-csi/csi_controller.hcl")
  hcl2 {
    enabled = true
  }
}
