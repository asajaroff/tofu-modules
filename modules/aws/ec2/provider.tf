# No `provider "aws" {}` block here on purpose: a module with its own local
# provider configuration cannot be called with count/for_each/depends_on by
# its caller (a hard Terraform restriction). Provider configuration is the
# calling module's responsibility — it already generates one via root.hcl.
#
# OpenTofu only, as of the `enabled` meta-argument (aws_iam_role_policy_attachment.ssm
# and the IPv6 security group rules in security_groups.tf): `lifecycle { enabled = ... }`
# is not part of Terraform's grammar at all and fails to parse there, regardless of
# Terraform's version — the >= 1.11 constraint below documents intent, it does not
# and cannot enforce "OpenTofu, not Terraform" on its own.
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }
}
