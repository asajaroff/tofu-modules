output "master_primary_info" {
  description = "Same shape as the ec2 module's instance_info, for the single primary control-plane node."
  value       = module.master_primary.instance_info
}

output "master_joiner_info" {
  description = "Same shape as the ec2 module's instance_info, merged across all additional (non-primary) control-plane nodes. Empty map when masters_count == 1."
  value       = merge({}, [for m in values(module.master_joiner) : m.instance_info]...)
}

output "worker_info" {
  description = "Same shape as the ec2 module's instance_info, merged across all worker nodes. Empty map when workers_count == 0."
  value       = merge({}, [for w in values(module.worker) : w.instance_info]...)
}

output "security_group_id" {
  description = "ID of the security group shared by every node in this cluster."
  value       = aws_security_group.cluster.id
}

output "master_endpoint_parameter_name" {
  description = "SSM parameter name holding the primary master's private IP (String, not secret)."
  value       = aws_ssm_parameter.master_endpoint.name
}

output "node_token_parameter_name" {
  description = "SSM parameter name holding the cluster join token (SecureString). Value is intentionally not exposed as an output."
  value       = aws_ssm_parameter.node_token.name
}

output "k3s_read_policy_arn" {
  description = "ARN of the read-only IAM policy this module attaches to every node it creates."
  value       = aws_iam_policy.k3s_read.arn
}
