output "namespace_names" {
  description = "List of created namespace names"
  value       = [for ns in nomad_namespace.this : ns.name]
}
