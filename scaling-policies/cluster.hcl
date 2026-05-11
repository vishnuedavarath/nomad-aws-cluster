scaling "cluster_drain_baseline" {
  enabled = true
  min     = {{ with nomadVar "nomad/jobs/autoscaler" }}{{ .client_min }}{{ end }}
  max     = {{ with nomadVar "nomad/jobs/autoscaler" }}{{ .client_max }}{{ end }}

  policy {
    evaluation_interval = "10s"
    cooldown            = "20s"

    check "cpu_allocated" {
      source = "nomad-apm"
      query  = "node_percentage-allocated_cpu/hashistack/class"

      strategy "target-value" {
        target = 70
      }
    }

    check "mem_allocated" {
      source = "nomad-apm"
      query  = "node_percentage-allocated_memory/hashistack/class"

      strategy "target-value" {
        target = 70
      }
    }

    target "aws-asg" {
      dry-run             = "false"
      aws_asg_name        = "{{ with nomadVar "nomad/jobs/autoscaler" }}{{ .client_asg_name }}{{ end }}"
      node_class          = "hashistack"
      node_drain_deadline = "10m"
    }
  }
}
