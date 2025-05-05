job "redis-immich" {
  datacenters = ["homelab"]
  type = "service"

  group "redis-immich" {
    count = 1

    restart {
      attempts = 3
      interval = "2m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "redis" {
        static       = 6379
        to           = 6379
      }
    }
    task "redis-immich-master" {
      driver = "docker"
      config {
        image = "library/redis:7.2.1"
        args =  ["redis-server", "${NOMAD_ALLOC_DIR}/redis.conf", "--loglevel", "warning"]
        ports = [ "redis" ]
      }
      resources {
        cpu = 10
        memory = 100
      }
      template {
        destination = "${NOMAD_ALLOC_DIR}/redis.conf"
        change_mode = "signal"
        change_signal = "SIGINT"
        data = <<EOH
          maxmemory 0
          min-slaves-max-lag 5
          min-slaves-to-write 0
          rdbchecksum yes
          rdbcompression yes
          repl-diskless-sync yes
        EOH
      }
      service {
        name = "redis-immich"
        port = "redis"
        check {
          name = "alive"
          type = "tcp"
          interval = "15s"
          timeout  = "2s"
        }
      }
    }
  }
}

