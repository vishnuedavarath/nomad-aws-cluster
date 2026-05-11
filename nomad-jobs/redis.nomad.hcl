job "redis" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${node.class}"
    value     = "worker"
  }

  group "cache" {
    count = 1

    network {
      port "redis" {
        to = 6379
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:7-alpine"
        ports = ["redis"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
