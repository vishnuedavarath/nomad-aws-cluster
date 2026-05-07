job "webapp" {
  datacenters = ["dc1"]
  type        = "service"

  group "app" {
    count = 2

    network {
      port "http" {
        to = 5000
      }
    }

    task "webapp" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo"
        ports = ["http"]
        args = [
          "-listen", ":5000",
          "-text", "Hello from Nomad!",
        ]
      }

      resources {
        cpu    = 50
        memory = 32
      }
    }
  }
}
