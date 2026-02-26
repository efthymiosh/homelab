resource "nomad_job" "paperless-redis" {
  jobspec = file("./nomad/paperless/redis.hcl")
}

resource "nomad_job" "paperless_ngx" {
  jobspec = file("./nomad/paperless/paperless.hcl")
}

resource "nomad_job" "paperless_ai" {
  jobspec = file("./nomad/paperless/paperless_ai.hcl")
}

resource "nomad_job" "marimo" {
  jobspec = file("./nomad/marimo/marimo.hcl")
}

resource "nomad_job" "llama-cpp" {
  jobspec = file("./nomad/ai/llama-cpp.hcl")
}

resource "nomad_job" "voice-agent" {
  jobspec = file("./nomad/ai/voice-agent.hcl")
}
