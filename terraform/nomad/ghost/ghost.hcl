job "ghost" {
  datacenters = ["homelab"]

  # Service type jobs optimize for long-lived services. This is
  # the default but we can change to batch for short-lived tasks.
  type = "service"

  # Priority controls our access to resources and scheduling priority.
  # This can be 1 to 100, inclusively, and defaults to 50.
  priority = 80

  # Restrict our job to only linux. We can specify multiple
  # constraints as needed.
  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

  # Configure the job to perform rolling updates
  update {
    # Stagger updates every 10 seconds
    stagger = "10s"

    # Update a single task at a time
    max_parallel = 1
  }

  # Create a 'main' group. Each task in the group will be
  # scheduled onto the same machine.
  group "main" {
    # Control the number of instances of this groups.
    # Defaults to 1
    # count = 1

    # Configure the restart policy for the task group. If not provided, a
    # default is used based on the job type.
    restart {
      # The number of attempts to run the job within the specified interval.
      attempts = 10
      interval = "5m"

      # A delay between a task failing and a restart occurring.
      mode = "delay"
    }
    # Mode controls what happens when a task has restarted "attempts"
    # times within the interval. "delay" mode delays the next restart
    # till the next interval. "fail" mode does not restart the task if
    # "attempts" has been hit within the interval.500
    # Define a task to run
    task "website" {
      # Use Docker to run the task.
      driver = "docker"

      # Configure Docker driver with the image
      config {
        image = "ghost:latest"
        port_map {
          http = 2368
        }
        # ssl = true
        # auth {
        #      username = "{{ registry_user }}"
        #      password = "{{ registry_password }}"
        #      server_address = "{{ registry_host }}:{{ registry_port }}"
        # }
        # dns_servers = ["172.17.0.1"]
      }

      service {
        name = "ghost"
        tags = ["http", "routed"]
        port = "http"
        check {
          name = "alive"
          type = "tcp"
          interval = "30s"
          timeout = "2s"
        }
      }

      # We must specify the resources required for
      # this task to ensure it runs on a machine with
      # enough capacity.
      resources {
        cpu = 500 # 500 Mhz
        memory = 512 # 512MB
      }

      # The artifact block can be specified one or more times to download
      # artifacts prior to the task being started. This is convenient for
      # shipping configs or data needed by the task.
      # artifact {
      #     source = "http://foo.com/artifact.tar.gz"
      #     options {
      #         checksum = "md5:c4aa853ad2215426eb7d70a21922e794"
      #     }
      # }

      # Specify configuration related to log rotation
      logs {
          max_files = 3
          max_file_size = 10
      }

      # Controls the timeout between signalling a task it will be killed
      # and killing the task. If not set a default is used.
      kill_timeout = "20s"
    }
  }
}
