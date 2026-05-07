# Operator policy - day-to-day job management
namespace "*" {
  policy       = "write"
  capabilities = ["submit-job", "read-job", "list-jobs", "dispatch-job", "read-logs", "alloc-exec"]
}

node {
  policy = "read"
}

agent {
  policy = "read"
}
