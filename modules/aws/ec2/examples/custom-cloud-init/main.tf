#
# Example: Using the EC2 Module with Custom Cloud-Init Scripts
#
# This example demonstrates how to use custom bootstrap scripts and cloud-config
# files with the EC2 module instead of the default ones.
#

terraform {
  required_version = ">= 1.0"

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

# ============================================================================
# EC2 Module with Custom Cloud-Init Scripts
# ============================================================================

module "ec2_with_custom_cloudinit" {
  # Path to the EC2 module
  # Adjust this path based on where you've placed this example
  source = "../../" # Points to modules/ec2

  # Basic configuration
  name      = "custom-cloudinit-example"
  region    = var.region
  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id

  # Instance configuration
  instances = [
    {
      name                    = "custom-cloudinit-instance.example.com"
      instance_type           = "t3.micro"
      disable_api_termination = false
      volume_size             = 20
      public                  = true
    }
  ]

  # OS configuration
  os_family = "debian" # Can be: debian, ubuntu, freebsd, flatcar
  os_arch   = "amd64"  # Can be: amd64, arm64

  # SSH access — REPLACE with your actual IP(s); never use 0.0.0.0/0.
  # 203.0.113.0/32 below is a documentation-only placeholder (RFC 5737 TEST-NET-3).
  allow_ssh_ips = ["203.0.113.0/32"]

  # The module has no built-in SSH key management — either embed a public key
  # via ssh_authorized_keys/users in cloud-config-custom.yaml, or rely solely
  # on SSM (enable_ssm below), which needs no key at all.

  # AWS SSM (Session Manager) configuration
  enable_ssm = true

  # ========================================================================
  # CUSTOM CLOUD-INIT SCRIPTS
  # ========================================================================
  # These are the key variables for using custom cloud-init configuration!
  #
  # Use path.root to reference files relative to THIS directory
  # (where you run terraform apply)
  # ========================================================================

  custom_bootstrap_script = "${path.root}/bootstrap-custom.sh"
  custom_cloud_config     = "${path.root}/cloud-config-custom.yaml"

  # Tags
  tags = {
    Environment = "development"
    Project     = "cloud-init-example"
    ManagedBy   = "terraform"
  }
}

# ============================================================================
# Alternative Example: Using Default Scripts
# ============================================================================

# If you want to use the default scripts, simply omit the custom_* variables:
#
# module "ec2_with_default_cloudinit" {
#   source = "../../"
#
#   name      = "default-cloudinit-example"
#   region    = var.region
#   vpc_id    = var.vpc_id
#   subnet_id = var.subnet_id
#
#   instances = [
#     {
#       name                    = "default-instance.example.com"
#       instance_type           = "t3.micro"
#       disable_api_termination = false
#       volume_size             = 20
#       public                  = true
#     }
#   ]
#
#   os_family = "debian"
#
#   # Note: custom_bootstrap_script and custom_cloud_config are NOT specified
#   # The module will use the default scripts from modules/ec2/config/
# }

# ============================================================================
# Outputs
# ============================================================================

output "instance_info" {
  description = "Map of instance information including IDs and IP addresses"
  value       = module.ec2_with_custom_cloudinit.instance_info
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.ec2_with_custom_cloudinit.security_group_id
}
