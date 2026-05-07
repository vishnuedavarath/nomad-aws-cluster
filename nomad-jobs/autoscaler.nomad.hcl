variable "autoscaler_binary_url" {
  type        = string
  description = "S3 URL to the Nomad Autoscaler zip. Provided automatically by deploy-autoscaler.sh from terraform output."
}

job "autoscaler" {
  datacenters = ["dc1"]
  type        = "service"

  group "autoscaler" {
    count = 1

    network {
      port "http" {}
    }

    task "autoscaler" {
      driver = "raw_exec"

      config {
        command = "${NOMAD_TASK_DIR}/nomad-autoscaler"

        args = [
          "agent",
          "-config",
          "${NOMAD_TASK_DIR}/config.hcl",
          "-policy-dir",
          "${NOMAD_TASK_DIR}/policies/",
          "-http-bind-address",
          "0.0.0.0",
          "-http-bind-port",
          "${NOMAD_PORT_http}",
          "-log-level",
          "debug",
        ]
      }

      artifact {
        source      = var.autoscaler_binary_url
        destination = "${NOMAD_TASK_DIR}/"
      }

      # Autoscaler agent config
      template {
        data        = <<-EOF
          nomad {
            address = "http://{{env "attr.unique.network.ip-address"}}:4646"
            token   = "{{ with nomadVar "nomad/jobs/autoscaler" }}{{ .autoscaler_token }}{{ end }}"
          }

          telemetry {
            prometheus_metrics = true
          }

          apm "nomad-apm" {
            driver = "nomad-apm"
          }

          strategy "target-value" {
            driver = "target-value"
          }

          target "aws-asg" {
            driver = "aws-asg"
            config = {
              aws_region = "{{ with nomadVar "nomad/jobs/autoscaler" }}{{ .aws_region }}{{ end }}"
            }
          }
        EOF
        destination = "${NOMAD_TASK_DIR}/config.hcl"
      }

      # Cluster scaling policy - scales the client ASG based on resource allocation
      template {
        data        = <<-EOF
          scaling "cluster_policy" {
            enabled = true
            min     = {{ with nomadVar "nomad/jobs/autoscaler" }}{{ .client_min }}{{ end }}
            max     = {{ with nomadVar "nomad/jobs/autoscaler" }}{{ .client_max }}{{ end }}

            policy {
              cooldown            = "2m"
              evaluation_interval = "30s"

              check "cpu_allocated_percentage" {
                source = "nomad-apm"
                query  = "percentage-allocated_cpu"
                query_window = "1m"

                strategy "target-value" {
                  target = 70
                }
              }

              check "mem_allocated_percentage" {
                source = "nomad-apm"
                query  = "percentage-allocated_memory"
                query_window = "1m"

                strategy "target-value" {
                  target = 70
                }
              }

              target "aws-asg" {
                dry-run             = "false"
                aws_asg_name        = "{{ with nomadVar "nomad/jobs/autoscaler" }}{{ .client_asg_name }}{{ end }}"
                node_class          = "hashistack"
                node_drain_deadline = "5m"
              }
            }
          }
        EOF
        destination = "${NOMAD_TASK_DIR}/policies/policy.hcl"
      }

      resources {
        cpu    = 128
        memory = 128
      }
    }
  }
}
