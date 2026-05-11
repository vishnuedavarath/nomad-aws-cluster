variable "autoscaler_binary_url" {
  type        = string
  description = "S3 URL to the Nomad Autoscaler zip. Provided automatically by deploy-autoscaler.sh from terraform output."
}

variable "scaling_policies_url" {
  type        = string
  description = "S3 URL to the scaling policies zip."
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

      # Scaling policies from S3 (managed by Terraform)
      artifact {
        source      = var.scaling_policies_url
        destination = "${NOMAD_TASK_DIR}/policies/"
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

      resources {
        cpu    = 128
        memory = 128
      }
    }
  }
}
