job "enshrouded" {
  datacenters = ["homelab"]
  type        = "service"

  constraint {
    attribute = "${node.class}"
    operator  = "="
    value     = "jarvis"
  }

  group "enshrouded" {
    count = 1

    network {
      port "query" {
        static = 15637
      }
    }

    restart {
      attempts = 10
      interval = "30m"
      delay    = "30s"
      mode     = "delay"
    }

    task "update" {
      driver = "raw_exec"
      user   = "root"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      env {
        HOME = "/opt/enshrouded"
      }

      config {
        command = "/bin/bash"
        args = [
          "-c",
          "mkdir -p /opt/enshrouded && /usr/bin/steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir /opt/enshrouded/enshroudedserver +login anonymous +app_update 2278520 +quit || true"
        ]
      }
    }

    task "server" {
      driver = "raw_exec"
      user   = "root"

      env {
        HOME        = "/opt/enshrouded"
        WINEPREFIX  = "/opt/enshrouded/.wine"
        WINEDEBUG   = "-all"
      }

      config {
        command = "/bin/bash"
        args = [
          "-c",
          "cd /opt/enshrouded && exec /usr/bin/wine /opt/enshrouded/enshroudedserver/enshrouded_server.exe"
        ]
      }

      # Same as Ctrl+C in the manual run; give it time to save
      kill_signal  = "SIGINT"
      kill_timeout = "90s"

      # Scheduling hints only; raw_exec doesn't enforce limits
      resources {
        cpu    = 4000
        memory = 8192
      }
    }
  }
}
