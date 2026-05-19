job "prometheus" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${node.class}"
    value     = "worker"
  }

  group "monitoring" {
    count = 1

    network {
      port "http" {
        static = 9090
      }
    }

    service {
      name     = "prometheus"
      port     = "http"
      provider = "nomad"
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:v2.53.0"
        ports = ["http"]

        args = [
          "--config.file=/etc/prometheus/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--storage.tsdb.retention.time=1h",
        ]

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
        ]
      }

      template {
        data        = <<-EOF
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: "nomad_nodes"
    metrics_path: "/v1/metrics"
    params:
      format: ["prometheus"]
    consul_sd_configs:
      - server: "{{ env "attr.unique.network.ip-address" }}:8500"
        services:
          - "nomad-client"
          - "nomad"
    relabel_configs:
      - source_labels: [__meta_consul_service]
        target_label: service
      - source_labels: [__meta_consul_node]
        target_label: node
      - source_labels: [__address__]
        regex: "(.+):.*"
        replacement: "$${1}:4646"
        target_label: __address__
        EOF
        destination = "local/prometheus.yml"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
