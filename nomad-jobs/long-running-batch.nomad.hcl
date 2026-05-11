job "long-running-batch" {
  datacenters = ["dc1"]
  type        = "batch"

  constraint {
    attribute = "${node.class}"
    value     = "worker"
  }

  group "work" {
    count = 1

    reschedule {
      attempts  = 0
      unlimited = false
    }

    task "sleep" {
      driver = "docker"

      config {
        image   = "alpine:3"
        command = "sleep"
        args    = ["1800"]
      }

      resources {
        cpu    = 50
        memory = 32
      }
    }
  }
}
