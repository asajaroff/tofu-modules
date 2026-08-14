# All additional servers join through the FIRST server specifically (not a
# chain) — this is k3s's documented HA joining pattern, and means only one
# dependency edge is needed regardless of masters_count: every joiner
# references the primary's endpoint, never another joiner's.
locals {
  token_parameter_name    = aws_ssm_parameter.node_token.name
  endpoint_parameter_name = "${var.parameter_path_prefix}/master-endpoint"

  # Merged into every node's tags so its own boot script can discover which
  # cluster's SSM parameters to read — see config/*.yaml for why this can't
  # just be templated into the cloud-config instead.
  node_tags = merge(var.tags, { "k3s-parameter-path-prefix" = var.parameter_path_prefix })
}

module "master_primary" {
  source = "../ec2"

  name = "${var.name}-master-0"
  instances = [
    {
      name                    = "${var.name}-master-0"
      instance_type           = var.master_instance_type
      disable_api_termination = false
      volume_size             = var.root_volume_size
      public                  = false
    }
  ]

  vpc_id    = var.vpc_id
  subnet_id = var.subnet_ids[0 % length(var.subnet_ids)]
  region    = var.region
  os_family = "debian"
  os_arch   = var.os_arch

  allow_ssh_ips = var.allow_ssh_ips
  enable_ssm    = true

  additional_iam_policy_arns    = [aws_iam_policy.k3s_read.arn]
  additional_security_group_ids = [aws_security_group.cluster.id]

  custom_cloud_config = "${path.module}/config/master-primary.yaml"

  tags = local.node_tags
}

# Terraform writes this directly from the primary's own instance attribute —
# no instance ever self-reports its IP. From Terraform's perspective this
# parameter is fully created (not just "instance exists, cloud-init pending")
# before any joiner/worker that depends on it starts booting.
resource "aws_ssm_parameter" "master_endpoint" {
  name  = local.endpoint_parameter_name
  type  = "String"
  value = values(module.master_primary.instance_info)[0].private_ip
  tags  = var.tags
}

# for_each (not a fixed pair of named blocks) so this reads the same way
# regardless of masters_count — with masters_count validated to 1 or 3,
# range(masters_count - 1) is either empty or {0,1}, each round-robined onto
# a distinct subnet/AZ (offset by 1 so it doesn't reuse the primary's AZ).
module "master_joiner" {
  source   = "../ec2"
  for_each = { for i in range(var.masters_count - 1) : tostring(i + 1) => var.subnet_ids[(i + 1) % length(var.subnet_ids)] }

  name = "${var.name}-master-${each.key}"
  instances = [
    {
      name                    = "${var.name}-master-${each.key}"
      instance_type           = var.master_instance_type
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

  custom_cloud_config = "${path.module}/config/master-joiner.yaml"

  depends_on = [aws_ssm_parameter.master_endpoint]

  tags = local.node_tags
}
