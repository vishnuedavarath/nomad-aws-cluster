job "nginx" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${node.class}"
    value     = "worker"
  }

  group "web" {
    count = 3

    network {
      port "http" {
        to = 80
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:alpine"
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
