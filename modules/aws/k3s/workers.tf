# Same for_each-over-range pattern as master_joiner, round-robined across all
# subnets from index 0 — workers have no quorum constraint, so any count
# 0-3 is valid, not just odd numbers.
module "worker" {
  source   = "../ec2"
  for_each = { for i in range(var.workers_count) : tostring(i) => var.subnet_ids[i % length(var.subnet_ids)] }

  name = "${var.name}-worker-${each.key}"
  instances = [
    {
      name                    = "${var.name}-worker-${each.key}"
      instance_type           = var.worker_instance_type
      disable_api_termination = false
      volume_size             = var.root_volume_size
      public                  = false
    }
  ]

  vpc_id    = var.vpc_id
  subnet_id = each.value
  region    = var.region
  os_family = "debian"
  os_arch   = var.os_arch

  allow_ssh_ips = var.allow_ssh_ips
  enable_ssm    = true

  additional_iam_policy_arns    = [aws_iam_policy.k3s_read.arn]
  additional_security_group_ids = [aws_security_group.cluster.id]

  custom_cloud_config = "${path.module}/config/worker.yaml"

  depends_on = [aws_ssm_parameter.master_endpoint]

  tags = local.node_tags
}
