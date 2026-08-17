variable "name" {
  type        = string
  description = <<EOT
Name for the instance group.
Used as a prefix for IAM roles, security groups, and other resources.
EOT
}

variable "instances" {
  type = list(object({
    name                    = string
    instance_type           = string
    disable_api_termination = bool
    volume_size             = number
    public                  = bool
    }
  ))
  description = <<EOT
List of instances to create.
Example:
[
  {
    name                    = "instance1.example.com"
    instance_type           = "t3.micro"
    disable_api_termination = false
    volume_size             = 10
    public                  = true
  },
  {
    name                    = "instance2.example.com"
    instance_type           = "t3.large"
    disable_api_termination = false
    volume_size             = 20
    public                  = false
  }
]
EOT
}

variable "allow_ssh_ips" {
  type        = list(string)
  default     = ["192.168.1.1/32"]
  description = <<EOT
List IP address that will be allowed to SSH into the box.
Format is "123.123.123.123/32"
EOT
}

variable "allow_ssh_ipv6_ips" {
  type        = list(string)
  default     = []
  description = <<EOT
List of IPv6 addresses that will be allowed to SSH into the box.
Format is "2001:db8::1/128" for single addresses or "2001:db8::/64" for ranges.
If empty, no IPv6 SSH access will be allowed.
EOT
}

variable "additional_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<EOT
List of additional security group IDs to attach to the instances.
This allows attaching custom security groups (e.g., for HTTP, HTTPS, or application-specific rules)
alongside the module's default SSH security group.
Example: ["sg-12345678", "sg-87654321"]
EOT
}

variable "spot_enabled" {
  type        = bool
  default     = false
  description = "If true, the instance will be a spot-instance"
}

variable "spot_price" {
  type        = number
  default     = null
  description = <<EOT
The maximum hourly price you're willing to pay for a Spot Instance.
Defaults to null (no cap), which lets AWS use the On-Demand price as the
implicit ceiling — the modern, recommended default. Do not rely on the old
default of 0.005: current Spot pricing for virtually any instance type
exceeds that, so a request capped there will simply never fulfill.
EOT
}

variable "enable_ssm" {
  type        = bool
  default     = true
  description = <<EOT
If true, enables AWS Systems Manager (SSM) Session Manager for connecting to instances.
This controls both:
- Installation of the SSM agent during instance bootstrap
- Attachment of the AmazonSSMManagedInstanceCore IAM policy to the instance role
Set to false to skip SSM agent installation and save on bootstrap time if you only need SSH access.
EOT
}

variable "additional_iam_policy_arns" {
  type        = list(string)
  default     = []
  description = <<EOT
List of additional IAM policy ARNs to attach to the instance role.
Useful for granting instances access to AWS services like S3, DynamoDB, etc.
Example: ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
EOT
}

variable "os_arch" {
  type        = string
  default     = "amd64"
  description = <<EOT
Processor architecture, possible options:
- amd64
- arm64
EOT
}

variable "os_family" {
  type        = string
  default     = "debian"
  description = <<EOT
  The flavor for the EC2 instance to be deployed, possible options:
  - debian
  - ubuntu
  - freebsd
  - flatcar
EOT
}

variable "custom_ami_id" {
  type        = string
  default     = null
  description = <<EOT
Custom AMI ID to use for the instances instead of automatic OS family selection.
When specified, this overrides the os_family automatic AMI selection.
Useful for using golden images, hardened AMIs, or specific AMI versions.
Example: "ami-0123456789abcdef0"
EOT
}

variable "root_volume_encrypted" {
  type        = bool
  default     = true
  description = "If true, the root EBS volume will be encrypted"
}

variable "root_volume_kms_key_id" {
  type        = string
  default     = null
  description = <<EOT
KMS key ID to use for root volume encryption.
If not specified, the default AWS EBS encryption key will be used.
Only applies when root_volume_encrypted is true.
EOT
}

variable "tags" {
  default = {}
  type    = map(string)
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Region where the AWS provider will be configured and deployed"
}

variable "vpc_id" {
  type        = string
  description = "VPC where the resources will be created"
}

variable "subnet_id" {
  type        = string
  description = "Subnet where the resources will be created"
}

variable "custom_bootstrap_script" {
  type        = string
  default     = ""
  description = <<EOT
Path to a custom bootstrap script relative to the root module (where you invoke this module).
If provided, this will be used instead of the default bootstrap script.
Use path.root in your module invocation, e.g., "$${path.root}/scripts/custom-bootstrap.sh"
EOT
}

variable "custom_cloud_config" {
  type        = string
  default     = ""
  description = <<EOT
Path to a custom cloud-config YAML file relative to the root module (where you invoke this module).
If provided, this will be used instead of the default cloud-config.
Use path.root in your module invocation, e.g., "$${path.root}/config/custom-cloud-config.yaml"
EOT
}

variable "additional_ebs_volumes" {
  type = list(object({
    device_name           = string
    volume_size           = number
    volume_type           = optional(string, "gp3")
    iops                  = optional(number, null)
    throughput            = optional(number, null)
    encrypted             = optional(bool, true)
    kms_key_id            = optional(string, null)
    delete_on_termination = optional(bool, true)
    mount_point           = string
    filesystem_type       = optional(string, "ext4")
  }))
  default     = []
  description = <<EOT
List of additional EBS volumes to attach to ALL instances.
Each volume will be automatically formatted, mounted, and added to /etc/fstab.

Example:
[
  {
    device_name     = "/dev/sdf"
    volume_size     = 100
    volume_type     = "gp3"
    iops            = 3000
    throughput      = 125
    encrypted       = true
    mount_point     = "/data"
    filesystem_type = "ext4"
  }
]

Notes:
- device_name: Use /dev/sd[f-p] for additional volumes
- volume_type: gp3 (default), gp2, io1, io2, st1, sc1
- iops: Only for gp3, io1, io2 (gp3: 3000-16000, io1/io2: 100-64000)
- throughput: Only for gp3 (125-1000 MB/s)
- filesystem_type: ext4 (default), xfs, ext3
- Volumes are created per instance (if you have 3 instances, 3 volumes are created)
EOT
}

variable "enable_ipv6" {
  type        = bool
  default     = false
  description = <<EOT
Enable IPv6 address assignment for EC2 instances.
When enabled, each instance will be assigned an IPv6 address.

IMPORTANT: For IPv6 to work properly, your VPC must have:
1. An IPv6 CIDR block assigned to the VPC
2. An IPv6 CIDR block assigned to the subnet
3. An Internet Gateway (IGW) or Egress-Only Internet Gateway attached
4. Route table with IPv6 routes (::/0 -> IGW or Egress-Only IGW)

If IPv6 is enabled but routing is not properly configured, you may experience:
- NAT64 synthetic addresses (64:ff9b::/96) that don't work
- DNS timeouts when trying to reach external services
- SSH/Git operations failing after 30-60 second timeouts

Recommended: Set to false unless you have confirmed IPv6 routing is working.
EOT
}

variable "ipv6_address_count" {
  type        = number
  default     = 1
  description = <<EOT
Number of IPv6 addresses to assign to each instance.
Only used when enable_ipv6 is true.
Typical values: 1 (for a single IPv6 address per instance)
EOT
}

variable "enable_ipv6_security_rules" {
  type        = bool
  default     = false
  description = <<EOT
Enable IPv6 security group rules for ingress/egress traffic.
When enabled, allows:
- IPv6 SSH access (if allow_ssh_ipv6_ips is configured)
- IPv6 high ports (10000-65535) for return traffic and applications
- IPv6 egress to ::/0 (all outbound traffic)

Blocks all incoming IPv6 traffic on ports below 10000 (except SSH if configured).

Set to false if you want to use IPv4-only communication or if your VPC doesn't have proper IPv6 routing.
EOT
}

variable "route53_hosted_zone_id" {
  type        = string
  default     = null
  description = <<EOT
Route53 hosted zone ID where DNS records will be created.
If specified along with route53_subdomains, A records will be created pointing to the instance's public IP.
Example: "Z1234567890ABC"
EOT
}

variable "route53_subdomains" {
  type        = list(string)
  default     = []
  description = <<EOT
List of subdomain names to create as A records in the specified Route53 hosted zone.
Each subdomain will point to the instance's public IP address.
Only used when route53_hosted_zone_id is specified.
Example: ["app", "api", "www"] - these will be created as app.yourdomain.com, api.yourdomain.com, www.yourdomain.com
EOT
}
