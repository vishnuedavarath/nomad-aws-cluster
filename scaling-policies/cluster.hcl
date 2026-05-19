scaling "cluster_drain_baseline" {
  enabled = true
  min     = 2
  max     = 6

  policy {
    evaluation_interval = "60s"
    cooldown            = "20s"

    check "cpu_allocated" {
      source = "nomad-apm"
      query  = "node_percentage-allocated_cpu/worker/class"

      strategy "target-value" {
        target = 70
      }
    }

    check "mem_allocated" {
      source = "nomad-apm"
      query  = "node_percentage-allocated_memory/worker/class"

      strategy "target-value" {
        target = 70
      }
    }

    target "aws-asg" {
      dry-run             = "false"
      aws_asg_name        = "nomad-cluster-client-asg"
      node_class          = "worker"
      node_drain_deadline = "10m"
    }
  }
}
