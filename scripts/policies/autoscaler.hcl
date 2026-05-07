# Autoscaler policy - minimal permissions for scaling
namespace "*" {
  policy       = "read"
  capabilities = ["read-job", "list-jobs", "read-job-scaling", "scale-job"]
}

node {
  policy = "write"
}

# Required for the autoscaler to function
plugin {
  policy = "read"
}
