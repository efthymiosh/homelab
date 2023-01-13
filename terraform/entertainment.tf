resource "nomad_job" "plex" {
  jobspec = file("nomad/plex/plex.hcl")
  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "sonarr" {
  jobspec = file("nomad/plex/sonarr.hcl")
  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "radarr" {
  jobspec = file("nomad/plex/radarr.hcl")
  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "jackett" {
  jobspec = file("nomad/plex/jackett.hcl")
  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "bazarr" {
  jobspec = file("nomad/plex/bazarr.hcl")
  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "transmission" {
  jobspec = file("nomad/transmission/transmission.hcl")
  hcl2 {
    enabled = true
  }
}
