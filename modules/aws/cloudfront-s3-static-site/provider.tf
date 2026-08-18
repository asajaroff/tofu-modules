# OpenTofu only, as of the `enabled` meta-argument used on aws_s3_bucket_versioning.this
# in s3.tf: `lifecycle { enabled = ... }` isn't part of Terraform's grammar and fails to
# parse there — the >= 1.11 constraint below documents intent, it doesn't enforce it.
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}
