# Operator policy - broad admin powers for day-to-day cluster operations
# Use management token only for ACL changes
namespace "*" {
  policy       = "write"
  capabilities = ["submit-job", "read-job", "list-jobs", "dispatch-job", "read-logs", "alloc-exec", "alloc-lifecycle", "read-job-scaling", "scale-job"]
}

node {
  policy = "write"
}

agent {
  policy = "write"
}

operator {
  policy = "read"
}

plugin {
  policy = "read"
}
