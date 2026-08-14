variable "name" {
  type        = string
  description = "Name prefix for the cluster and all resources it creates (security group, IAM policy, node names, SSM parameters)."
}

variable "masters_count" {
  type        = number
  default     = 1
  description = <<EOT
Number of k3s server (control-plane) nodes, using k3s's embedded etcd datastore.

Only 1 or 3 are accepted. Embedded etcd requires an odd number of members for
real quorum tolerance: with 2 members, losing either one loses quorum
entirely, so a 2-node control plane is strictly worse than a 1-node one and
gains no fault tolerance. Use 1 for a non-HA lab/sandbox cluster, 3 for HA
(tolerates 1 node failure).
EOT

  validation {
    condition     = contains([1, 3], var.masters_count)
    error_message = "masters_count must be 1 or 3. Embedded etcd needs an odd member count for quorum; 2 provides no fault tolerance over 1 and is blocked."
  }
}

variable "workers_count" {
  type        = number
  default     = 0
  description = <<EOT
Number of dedicated k3s agent (worker-only) nodes. 0 is valid — the
control-plane node(s) schedule pods too in that case, matching a single-node
k3s deployment.
EOT

  validation {
    condition     = var.workers_count >= 0 && var.workers_count <= 3
    error_message = "workers_count must be between 0 and 3."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC where all cluster nodes will be created."
}

variable "subnet_ids" {
  type        = list(string)
  description = <<EOT
Subnets available for cluster nodes, one per AZ. Nodes are round-robined
across this list (subnet_ids[i % length(subnet_ids)]) so a 3-master control
plane actually spreads across AZs instead of landing in a single one.
EOT
}

variable "region" {
  type        = string
  description = "Region where the AWS provider is configured, passed straight through to each ec2 module call."
}

variable "master_instance_type" {
  type        = string
  default     = "t4g.medium"
  description = "Instance type for master (control-plane) nodes."
}

variable "worker_instance_type" {
  type        = string
  default     = "t4g.medium"
  description = "Instance type for worker (agent) nodes."
}

variable "os_arch" {
  type        = string
  default     = "arm64"
  description = "Processor architecture for all nodes: amd64 or arm64. Passed straight through to the ec2 module."
}

variable "root_volume_size" {
  type        = number
  default     = 20
  description = "Root EBS volume size (GB) for every node."
}

variable "allow_ssh_ips" {
  type        = list(string)
  default     = []
  description = <<EOT
IPv4 CIDRs allowed to SSH into cluster nodes. Fallback access path only — the
primary access path is SSM Session Manager (enable_ssm is always on for
every node this module creates). Never pass 0.0.0.0/0.
EOT
}

variable "parameter_path_prefix" {
  type        = string
  description = <<EOT
SSM Parameter Store path prefix under which this module stores the cluster
join token (SecureString) and the primary master's endpoint (String), e.g.
"/non-prod/sandbox/k3s". Must be unique per cluster — colliding prefixes
between two clusters would let one read the other's join token.
EOT
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to every resource this module creates."
}
