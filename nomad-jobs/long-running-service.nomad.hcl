job "long-running-service" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${node.class}"
    value     = "worker"
  }

  group "work" {
    count = 1

    task "loop" {
      driver = "docker"

      config {
        image   = "alpine:3"
        command = "/bin/sh"
        args    = ["-c", "sleep 1800 && echo 'done'"]
      }

      resources {
        cpu    = 50
        memory = 32
      }
    }
  }
}
