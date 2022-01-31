resource "nomad_job" "ghost" {
  jobspec = file("nomad/ghost/ghost.hcl")
  hcl2 {
    enabled = true
    vars =  {
      cloudflare_cert   = file("secrets/cloudflared/cert.pem")
      cloudflare_config = file("secrets/cloudflared/config.yml")
      cloudflare_tunnel = file("secrets/cloudflared/tunnel.json")
    }
  }
}
