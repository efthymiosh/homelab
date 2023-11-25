resource "nomad_job" "plex" {
  jobspec = file("nomad/plex/plex.hcl")
}

resource "nomad_job" "sonarr" {
  jobspec = file("nomad/plex/sonarr.hcl")
}

resource "nomad_job" "radarr" {
  jobspec = file("nomad/plex/radarr.hcl")
}

resource "nomad_job" "jackett" {
  jobspec = file("nomad/plex/jackett.hcl")
}

resource "nomad_job" "bazarr" {
  jobspec = file("nomad/plex/bazarr.hcl")
}

resource "nomad_job" "transmission" {
  jobspec = file("nomad/transmission/transmission.hcl")
}

resource "nomad_job" "sabnzbd" {
  jobspec = file("nomad/sabnzbd/sabnzbd.hcl")
}
