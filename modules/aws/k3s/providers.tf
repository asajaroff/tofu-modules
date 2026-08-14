# No provider "aws" {} block here on purpose — see ../ec2/provider.tf's
# comment. This module also calls ../ec2 with for_each (master_joiner,
# worker), so it must stay clean of local provider configuration too.
terraform {
  required_version = ">= 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
