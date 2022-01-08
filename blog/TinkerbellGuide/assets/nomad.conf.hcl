data_dir = "/var/lib/nomad"

server {
    bootstrap_expect = 1
    enabled = true
}
client {
    enabled = true
    options = {
        "docker.volumes.enabled" = "true"
    }
}
