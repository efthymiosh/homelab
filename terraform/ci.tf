resource "nomad_job" "woodpecker" {
  jobspec = file("./nomad/woodpecker-ci/woodpecker.hcl")
}
