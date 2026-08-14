# No `provider "aws" {}` block here on purpose: a module with its own local
# provider configuration cannot be called with count/for_each/depends_on by
# its caller (a hard Terraform restriction). Provider configuration is the
# calling module's responsibility — it already generates one via root.hcl.
terraform {
  required_version = ">= 1.1"

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
