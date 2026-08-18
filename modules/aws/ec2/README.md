# EC2 Module

**OpenTofu only as of v2.0.0.** This module uses the `lifecycle { enabled = ... }` meta-argument (`aws_iam_role_policy_attachment.ssm`, the IPv6 security group rules), which was added in OpenTofu 1.11 and has no equivalent in Terraform's grammar at all — it fails to parse there, on any Terraform version. Pin `<= v1.2.4` if you need Terraform compatibility.

A flexible OpenTofu module for provisioning EC2 instances with customizable configurations including multiple OS options, spot instances, and IAM role integration. The module has no built-in SSH key management — use SSM Session Manager (`enable_ssm`) or embed a public key yourself via `custom_cloud_config`'s `ssh_authorized_keys`/`users`.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Basic Example](#basic-example)
  - [OS Selection](#os-selection)
  - [Multiple Instances](#multiple-instances-with-different-configurations)
  - [Spot Instances](#spot-instance-configuration)
  - [Complete Production Example](#complete-production-example)
- [Network Requirements](#network-requirements)
- [Security Configuration](#security-configuration)
- [Accessing Instances](#accessing-instances)
- [Cloud-Init Customization](#cloud-init-customization)
- [Outputs](#outputs)
- [Troubleshooting](#troubleshooting)
- [Limitations & Known Issues](#limitations--known-issues)
- [Architecture](#architecture)
- [Terraform Documentation](#requirements)

## Features

- **Multiple OS Support**: Deploy Debian, Ubuntu, FreeBSD, or Flatcar Container Linux instances
- **Architecture Flexibility**: Support for both amd64 and arm64 architectures
- **Spot Instance Support**: Optional spot instance provisioning with configurable pricing
- **IAM Integration**: Built-in IAM role and instance profile creation
- **AWS SSM Support**: Optional AWS Session Manager integration for secure access
- **Cloud-init Configuration**: Automated instance initialization and software installation
- **Security Group Management**: Preconfigured security groups with customizable SSH access
- **Multi-Instance Deployment**: Deploy multiple instances with different configurations in a single module call
- **IPv6 Support**: Optional IPv6 configuration (disabled by default to prevent NAT64 issues)

## Quick Start

```bash
# 1. Clone or reference the module
# 2. Create a basic configuration
cat > main.tf <<'EOF'
module "ec2" {
  source = "./modules/ec2"

  name      = "my-instances"
  vpc_id    = "vpc-xxxxx"      # Replace with your VPC ID
  subnet_id = "subnet-xxxxx"   # Replace with your subnet ID

  allow_ssh_ips = ["YOUR_IP/32"]  # Replace with your IP

  instances = [{
    name                    = "test.example.com"
    instance_type           = "t3.micro"
    disable_api_termination = false
    volume_size             = 20
    public                  = true
  }]
}

output "instance_ip" {
  value = module.ec2.instance_info["test.example.com"].public_ip
}
EOF

# 3. Deploy
terraform init
terraform plan
terraform apply

# 4. Connect — via SSM (no key needed):
aws ssm start-session --target $(terraform output -json instance_info | jq -r 'keys[0]')
# ...or via SSH, only if you embedded a public key yourself in cloud-config:
ssh admin@$(terraform output -raw instance_ip)
```

## Prerequisites

- **Terraform/OpenTofu** >= 1.1
- **AWS CLI** configured with appropriate credentials
- **VPC with appropriate networking**:
  - For public instances: Subnet with route to Internet Gateway
  - For private instances: Subnet with route to NAT Gateway
- Basic understanding of AWS networking concepts

## Usage

### Basic Example

```hcl
module "ec2_instances" {
  source = "./modules/ec2"

  name      = "my-app"
  vpc_id    = "vpc-12345678"
  subnet_id = "subnet-87654321"

  instances = [
    {
      name                    = "web-server.example.com"
      instance_type           = "t3.micro"
      disable_api_termination = false
      volume_size             = 20
      public                  = true
    }
  ]
}
```

### OS Selection

The module supports multiple operating systems and architectures.

#### Ubuntu 22.04 LTS (Default: Debian)

```hcl
module "ubuntu_instance" {
  source = "./modules/ec2"

  name = "ubuntu-pool"
  vpc_id    = "vpc-12345678"
  subnet_id = "subnet-87654321"

  os_family = "ubuntu"
  os_arch   = "amd64"

  instances = [
    {
      name                    = "ubuntu.example.com"
      instance_type           = "t3.micro"
      disable_api_termination = false
      volume_size             = 20
      public                  = true
    }
  ]
}
```

#### Flatcar Container Linux

```hcl
module "flatcar_instance" {
  source = "./modules/ec2"

  name = "flatcar-pool"
  vpc_id    = "vpc-12345678"
  subnet_id = "subnet-87654321"

  os_family = "flatcar"
  os_arch   = "amd64"  # or "arm64"

  instances = [
    {
      name                    = "flatcar.example.com"
      instance_type           = "t3.micro"
      disable_api_termination = false
      volume_size             = 20
      public                  = true
    }
  ]
}
```

#### FreeBSD 14.1 on ARM64

```hcl
module "freebsd_arm" {
  source = "./modules/ec2"

  name = "freebsd-pool"
  vpc_id    = "vpc-12345678"
  subnet_id = "subnet-87654321"

  os_family = "freebsd"
  os_arch   = "arm64"

  instances = [
    {
      name                    = "freebsd.example.com"
      instance_type           = "t4g.micro"  # Graviton2
      disable_api_termination = false
      volume_size             = 20
      public                  = true
    }
  ]
}
```

### Multiple Instances with Different Configurations

```hcl
module "ec2_instances" {
  source = "./modules/ec2"

  name = "multi-tier-app"
  vpc_id    = "vpc-12345678"
  subnet_id = "subnet-87654321"

  instances = [
    {
      name                    = "web.example.com"
      instance_type           = "t3.micro"
      disable_api_termination = false
      volume_size             = 20
      public                  = true
    },
    {
      name                    = "db.example.com"
      instance_type           = "t3.large"
      disable_api_termination = true
      volume_size             = 100
      public                  = false
    }
  ]

  os_family = "ubuntu"
  os_arch   = "amd64"
  region    = "us-west-2"

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Spot Instance Configuration

```hcl
module "ec2_spot" {
  source = "./modules/ec2"

  pool_name     = "spot-pool"
  vpc_id        = "vpc-12345678"
  subnet_id     = "subnet-87654321"
  spot_enabled  = true
  spot_price    = 0.01

  instances = [
    {
      name                    = "batch-worker.example.com"
      instance_type           = "t3.medium"
      disable_api_termination = false
      volume_size             = 30
      public                  = false
    }
  ]
}
```

### Complete Production Example

```hcl
# VPC and networking (separate module/resources)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false  # HA setup
}

# EC2 instances in private subnet
module "app_servers" {
  source = "./modules/ec2"

  name = "production-app"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnets[0]  # Private subnet with NAT

  os_family = "ubuntu"
  os_arch   = "amd64"
  region    = "us-east-1"

  allow_ssh_ips   = ["203.0.113.0/32"]  # Your office IP
  enable_ssm =true

  instances = [
    {
      name                    = "app-01.prod.example.com"
      instance_type           = "t3.medium"
      disable_api_termination = true
      volume_size             = 50
      public                  = false
    },
    {
      name                    = "app-02.prod.example.com"
      instance_type           = "t3.medium"
      disable_api_termination = true
      volume_size             = 50
      public                  = false
    }
  ]

  tags = {
    Environment = "production"
    Terraform   = "true"
    ManagedBy   = "terraform"
  }
}

# Attach additional IAM policy for S3 access
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = module.app_servers.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Outputs
output "instance_details" {
  value = module.app_servers.instance_info
}
```

## Network Requirements

### Public Instances (`public = true`)

**Requires:**
- Subnet with route to Internet Gateway (`0.0.0.0/0 → igw-xxx`)
- Public IP assignment enabled (handled automatically by module)

**Use cases:**
- Web servers requiring direct internet access
- Jump boxes/bastion hosts
- Development/testing environments

### Private Instances (`public = false`)

**Requires:**
- Subnet with route to NAT Gateway (`0.0.0.0/0 → nat-xxx`) for internet access
- **Or**: VPC endpoints for AWS services (SSM, S3, etc.) if no internet access needed

**Use cases:**
- Production application servers
- Database servers
- Internal services
- Enhanced security posture

**Note**: Private instances can still access the internet through NAT Gateway for package updates, git cloning, etc.

### IPv6 Configuration

**Default**: IPv6 is **disabled** by default to prevent connectivity issues.

**Common Issue**: When IPv6 is enabled without proper VPC configuration, you may experience:
- NAT64 synthetic addresses (64:ff9b::/96) that don't work
- Git/SSH operations timing out after 30-60 seconds
- DNS returning non-functional IPv6 addresses

**To enable IPv6**, you must:
1. Ensure your VPC has IPv6 CIDR blocks configured
2. Configure Internet Gateway or Egress-Only Internet Gateway
3. Set up proper IPv6 routes in your route table
4. Enable IPv6 in the module:

```hcl
module "ec2_instances" {
  source = "./modules/ec2"

  enable_ipv6                = true
  enable_ipv6_security_rules = true  # Allows outbound traffic, blocks inbound ports < 10000
  ipv6_address_count         = 1

  # Optional: Allow IPv6 SSH access
  allow_ssh_ipv6_ips = ["2001:db8::/32"]

  # ... other configuration ...
}
```

**Security**: IPv6 rules allow all outbound traffic and incoming traffic only on ports 10000-65535.

📖 **See [IPv6-CONFIGURATION.md](./IPv6-CONFIGURATION.md) for detailed setup instructions and troubleshooting.**

## Security Configuration

### Built-in Security Features

- ✅ **IMDSv2 Enforced**: Prevents SSRF attacks on instance metadata
- ✅ **Egress Allowed**: All outbound traffic permitted for updates/packages
- ✅ **SSH Restricted**: Ingress limited to specified IP addresses only
- ✅ **SSM Access**: Optional Session Manager for keyless access
- ✅ **Latest AMIs**: Automatically uses most recent official images

### SSH Access Control

Configure which IP addresses can SSH into your instances using the `allow_ssh_ips` variable (accepts a list):

```hcl
module "ec2_instances" {
  source = "./modules/ec2"

  # ... other variables ...

  # Single IP
  allow_ssh_ips = ["203.0.113.0/32"]

  # Multiple IPs/ranges
  allow_ssh_ips = [
    "203.0.113.0/32",    # Office
    "198.51.100.0/24",   # VPN range
  ]
}
```

**Important**: The default value is `["192.168.1.1/32"]`. Always set this to your actual IP address or CIDR block for security.

**Get your current IP:**
```bash
# Linux/macOS
curl -s ifconfig.me

# Use in Terraform
allow_ssh_ips = ["${chomp(data.http.myip.response_body)}/32"]
```

### Security Recommendations

1. **Restrict SSH Access**: Always specify `allow_ssh_ips` - don't rely on defaults
2. **Use SSM When Possible**: Enable `enable_ssm` and use Session Manager instead of SSH
3. **Private Subnets for Production**: Use private subnets with NAT for production workloads
4. **Enable Termination Protection**: Set `disable_api_termination = true` for critical instances
5. **Regular Updates**: Module uses `most_recent = true` for AMIs, but patch instances regularly
6. **Least Privilege IAM**: Attach only necessary IAM policies to the instance role
7. **Monitor Access**: Enable CloudTrail and VPC Flow Logs for audit trails

## Accessing Instances

The module has no built-in SSH key management — it creates no key pair and attaches none by default. Pick one of the two methods below.

### AWS Session Manager (recommended, no key needed)

If `enable_ssm` is true (default), connect via AWS SSM without SSH keys:

```bash
# Connect to instance
aws ssm start-session --target <instance-id>

# Port forwarding (e.g., for web apps)
aws ssm start-session --target <instance-id> \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["80"],"localPortNumber":["8080"]}'
```

**Benefits of SSM:**
- No SSH keys required
- No open inbound ports needed
- Works with both public and private instances
- Centralized access logging
- Session recording capabilities

This method doesn't require SSH keys or open ports and works with both public and private instances.

### SSH Access

Requires embedding a public key yourself, via `custom_cloud_config`'s `ssh_authorized_keys`/`users` section — see `examples/custom-cloud-init/cloud-config-custom.yaml` for a working example. `allow_ssh_ips` only controls which source IPs the security group permits; it doesn't provision any key.

**Default usernames on the module's stock AMIs:**

| OS Family | Default Username | Notes |
|-----------|------------------|-------|
| `debian` | `admin` | Debian official AMI default user |
| `ubuntu` | `ubuntu` | Ubuntu official AMI default user |
| `freebsd` | `ec2-user` | FreeBSD official AMI default user |
| `flatcar` | `core` | Flatcar Container Linux default user |

## Cloud-Init Customization

The module includes bootstrap scripts for each OS that run on first boot:

| OS | Files | Installed Packages |
|----|-------|-------------------|
| **Debian** | `config/bootstrap-debian.sh`<br>`config/cloud-config-debian.yaml` | ansible, git, python3, neovim, curl (via apt) |
| **Ubuntu** | `config/bootstrap-ubuntu.sh`<br>`config/cloud-config-ubuntu.yaml` | ansible, git, python3, neovim, curl (via apt) |
| **FreeBSD** | `config/bootstrap-freebsd.sh`<br>`config/cloud-config-freebsd.yaml` | ansible, git, python3, neovim, curl (via pkg)<br>SSM Agent for FreeBSD |
| **Flatcar** | `config/bootstrap-flatcar.sh`<br>`config/cloud-config-flatcar.yaml` | SSM Agent (runs as Docker container)<br>Container-optimized OS |

### What Happens on First Boot

1. **Bootstrap script** runs (installs SSM agent, basic packages)
2. **Cloud-config** applies (SSH keys, user configuration)
3. **Instance becomes ready** for use

### Customizing Bootstrap

To customize what gets installed:

1. **Fork the module** or copy to your own repository
2. **Edit config files** in `config/` directory
3. **Modify as needed**:
   - Add/remove packages in bootstrap scripts
   - Change cloud-config settings
   - Add custom scripts

**Example modification** (`config/bootstrap-ubuntu.sh`):
```bash
#!/bin/bash
# Add your custom packages here
apt-get update
apt-get install -y ansible git python3 neovim curl docker.io
```

## Outputs

The module provides the following outputs for integration with other resources:

| Output | Description | Type | Usage Example |
|--------|-------------|------|---------------|
| `instance_info` | Map of instance details (ID, IPs, type), keyed by the logical `name` you gave each instance in `instances` | `map(object)` | Get instance metadata |
| `security_group_id` | Security group ID | `string` | Add additional rules |
| `iam_role_name` | IAM role name | `string` | Attach additional policies |
| `iam_role_arn` | IAM role ARN | `string` | Reference in IAM policies |
| `iam_instance_profile_name` | Instance profile name | `string` | Use in other modules |
| `ami_id` | Selected AMI ID | `string` | Track which AMI was used |
| `instance_arns` | Map of instance ARNs | `map(string)` | Use in resource policies |
| `ebs_volume_ids` / `ebs_volume_arns` | Maps of additional EBS volume IDs/ARNs (key: `instance_name-volN`) | `map(string)` | Reference attached volumes |
| `route53_record_names` / `route53_record_ids` | Maps of created Route53 record FQDNs/IDs (only if `route53_hosted_zone_id` set) | `map(string)` | Look up DNS names |

### Usage Examples

**Get instance information:**
```bash
# View all instance details
terraform output instance_info

# Get a specific instance's IP — keyed by the logical name from `instances`
terraform output -json instance_info | jq -r '."web.example.com".public_ip'
```

**Attach additional IAM policy:**
```hcl
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = module.ec2_instances.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
```

**Add security group rule:**
```hcl
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = module.ec2_instances.security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}
```

**Reference in other resources:**
```hcl
resource "aws_lb_target_group_attachment" "app" {
  for_each = module.ec2_instances.instance_info

  target_group_arn = aws_lb_target_group.app.arn
  target_id        = each.value.id
  port             = 80
}
```

## Troubleshooting

### Cannot SSH to Instance

**Symptoms**: Connection timeout or "Connection refused"

**Diagnostic steps:**
```bash
# 1. Check security group allows your IP
terraform output security_group_id
aws ec2 describe-security-groups --group-ids <sg-id>

# 2. Verify instance has public IP (if using public subnet)
terraform output instance_info

# 3. Check you're using correct username
# See "Default usernames" table under Accessing Instances above

# 4. Confirm a public key was actually embedded in cloud-config — the module
#    doesn't manage SSH keys itself, see the SSH Access section above
```

**Solutions:**
- Add your IP to `allow_ssh_ips`
- Ensure instance has `public = true` if in public subnet
- Check route table has IGW route
- Use correct SSH username for OS

### Cannot Clone Git Repositories / No Internet Access

**Symptoms**: `git clone` hangs at "Cloning into...", package updates fail

**Diagnostic steps from instance:**
```bash
# Test DNS resolution
nslookup github.com

# Test internet connectivity
ping -c 4 8.8.8.8
ping -c 4 github.com

# Test HTTPS connectivity
curl -I https://github.com

# Check routing
ip route show default
```

**Common causes and solutions:**

1. **Private subnet without NAT Gateway**
   - **Symptom**: No default route or route to NAT
   - **Solution**: Add NAT Gateway to subnet's route table
   ```bash
   # Check route table
   aws ec2 describe-route-tables \
     --filters "Name=association.subnet-id,Values=<subnet-id>"
   ```

2. **Public subnet without IGW route**
   - **Symptom**: `public = true` but no internet
   - **Solution**: Add IGW route (`0.0.0.0/0 → igw-xxx`) to route table

3. **DNS resolution issues**
   - **Symptom**: Can ping 8.8.8.8 but not github.com
   - **Solution**: Check VPC DNS settings (`enableDnsHostnames`, `enableDnsSupport`)

### Instance Recreation on Apply

**Symptom**: Terraform wants to destroy and recreate instance

**Cause**: Changed the `name` field in an instance within the `instances` list

**Why**: Terraform uses `name` as the resource key (see `for_each` in `main.tf`)

**Solutions:**
1. **Don't change names** - Use tags for metadata
2. **Use terraform state mv** to preserve instance:
   ```bash
   terraform state mv \
     'module.ec2.aws_instance.this["old-name"]' \
     'module.ec2.aws_instance.this["new-name"]'
   ```
3. **Plan migrations** - Accept recreation for major changes

### SSM Session Manager Not Working

**Symptoms**: Cannot start SSM session, "TargetNotConnected" error

**Diagnostic steps:**
```bash
# Check if SSM agent is running
sudo systemctl status amazon-ssm-agent  # Debian/Ubuntu
sudo service amazon-ssm-agent status    # FreeBSD
docker ps | grep ssm                    # Flatcar

# Check IAM permissions
aws iam get-role-policy \
  --role-name <role-name> \
  --policy-name SSMPolicy
```

**Solutions:**
- Ensure `enable_ssm = true` in module call
- Verify IAM role has SSM permissions (module creates this automatically)
- For private instances: Add VPC endpoints for SSM (or use NAT Gateway)
- Check instance has internet access to reach SSM service

### Wrong AMI Selected

**Symptom**: Instance launches with unexpected OS version

**Diagnostic:**
```bash
# Check which AMI was selected
terraform output ami_id

# Query AMI details
aws ec2 describe-images --image-ids <ami-id>
```

**Solution:**
- Module uses `most_recent = true` - this is intentional
- To pin specific AMI version, modify data source filters in `data.tf`
- Check AWS region - AMI IDs differ per region

## Limitations & Known Issues

### Current Limitations

1. **Instance Name Changes Cause Recreation**
   - Changing the `name` field in `instances` destroys and recreates the instance
   - Terraform limitation due to `for_each` key
   - Workaround: Use tags for changeable metadata

2. **Shared IAM Role**
   - All instances share the same IAM role
   - Cannot have different permissions per instance
   - Workaround: Use separate module calls with different `name` values

3. **Single Security Group**
   - All instances share one security group
   - Cannot have per-instance firewall rules
   - Workaround: Create additional security groups and attach manually

4. **Embedded Cloud-Init**
   - Cloud-init configs are built into the module
   - Not customizable without forking the module
   - Workaround: Fork module and modify `config/` files

5. **Root Volume Only**
   - No support for additional EBS volumes
   - Only root volume is managed
   - Workaround: Create additional volumes with separate `aws_ebs_volume` resources

6. **No Backup Management**
   - No built-in snapshot/backup functionality
   - No automated AMI creation
   - Workaround: Use AWS Backup or separate backup solution

### Known Issues

- ⚠️ Auto-generated docs section may be outdated (regenerate with `terraform-docs`)
- ⚠️ FreeBSD SSM agent installation may fail on first boot (requires manual retry)
- ⚠️ Flatcar SSM agent requires Docker, which may take time to initialize

### Roadmap / Future Enhancements

- [ ] Support for additional EBS volumes
- [ ] Configurable cloud-init via variables
- [ ] Per-instance security group support
- [ ] Automated backup/snapshot configuration
- [ ] Support for Elastic IPs
- [ ] Load balancer target group attachment
- [ ] Auto Scaling Group variant

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    VPC (vpc_id)                         │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │         Subnet (subnet_id)                      │   │
│  │                                                 │   │
│  │  ┌──────────────────────────────────────────┐  │   │
│  │  │       EC2 Instance/s (name)              │  │   │
│  │  │                                          │  │   │
│  │  │  ┌────────────────────────────────┐     │  │   │
│  │  │  │  Selected AMI (os_family)      │     │  │   │
│  │  │  │  - debian / ubuntu / freebsd   │     │  │   │
│  │  │  │  - flatcar                     │     │  │   │
│  │  │  │  Architecture: amd64 / arm64   │     │  │   │
│  │  │  └────────────────────────────────┘     │  │   │
│  │  │                                          │  │   │
│  │  │  Security Group (allow_ssh_ips)         │◄─┼───┼── SSH from specified IPs
│  │  │  IAM Instance Profile + Role             │  │   │
│  │  │  Cloud-init (bootstrap + config)        │  │   │
│  │  │  Root Volume (gp3, configurable size)   │  │   │
│  │  └──────────────────────────────────────────┘  │   │
│  │                      │                          │   │
│  │                      │ Internet Access          │   │
│  └──────────────────────┼──────────────────────────┘   │
│                         │                              │
│                    ┌────▼────┐                         │
│    Public:         │   IGW   │                         │
│    Private:        └─────────┘                         │
│                    or                                  │
│                    ┌─────────┐                         │
│                    │   NAT   │                         │
│                    └─────────┘                         │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
                  AWS Services
                  - SSM (Session Manager) ◄── enable_ssm
                  - EC2 API
                  - CloudWatch Logs
```

### Component Overview

- **VPC/Subnet**: Provided by user, must have appropriate routing
- **EC2 Instances**: Created with `for_each` loop based on `instances`
- **Security Group**: Shared across all instances, SSH ingress + all egress
- **IAM Role**: Shared role with SSM policy (if `enable_ssm` is true)
- **AMI Selection**: Automatic based on `os_family` and `os_arch`
- **Cloud-init**: OS-specific bootstrap on first launch
- **SSH Access**: Not module-managed — embed a key via `custom_cloud_config`, or use SSM instead

---

## Important Notes

- **Instance Recreation**: Changing the `name` field in `instances` will cause the instance to be destroyed and recreated
- **Metadata Security**: IMDSv2 is enforced for enhanced security (`http_tokens = "required"`)
- **Volume Management**: Root volumes are configured with gp3 (General Purpose SSD) and are deleted on instance termination
- **IAM Roles**: A shared IAM role and instance profile are created for all instances using the `name` variable
- **Spot Instances**: When enabled, instances use the `stop` interruption behavior to preserve data during spot interruptions

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | ~> 2.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | 2.3.7 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ebs_volume.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_route53_record.subdomains](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_volume_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_vpc_security_group_egress_rule.all_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.all_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.high_ports_tcp_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.high_ports_udp_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ssh_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ssh_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_ami.debian](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.flatcar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.freebsd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_subnet.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [cloudinit_config.debian](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.flatcar](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.freebsd](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.ubuntu](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_ebs_volumes"></a> [additional\_ebs\_volumes](#input\_additional\_ebs\_volumes) | List of additional EBS volumes to attach to ALL instances.<br/>Each volume will be automatically formatted, mounted, and added to /etc/fstab.<br/><br/>Example:<br/>[<br/>  {<br/>    device\_name     = "/dev/sdf"<br/>    volume\_size     = 100<br/>    volume\_type     = "gp3"<br/>    iops            = 3000<br/>    throughput      = 125<br/>    encrypted       = true<br/>    mount\_point     = "/data"<br/>    filesystem\_type = "ext4"<br/>  }<br/>]<br/><br/>Notes:<br/>- device\_name: Use /dev/sd[f-p] for additional volumes<br/>- volume\_type: gp3 (default), gp2, io1, io2, st1, sc1<br/>- iops: Only for gp3, io1, io2 (gp3: 3000-16000, io1/io2: 100-64000)<br/>- throughput: Only for gp3 (125-1000 MB/s)<br/>- filesystem\_type: ext4 (default), xfs, ext3<br/>- Volumes are created per instance (if you have 3 instances, 3 volumes are created) | <pre>list(object({<br/>    device_name           = string<br/>    volume_size           = number<br/>    volume_type           = optional(string, "gp3")<br/>    iops                  = optional(number, null)<br/>    throughput            = optional(number, null)<br/>    encrypted             = optional(bool, true)<br/>    kms_key_id            = optional(string, null)<br/>    delete_on_termination = optional(bool, true)<br/>    mount_point           = string<br/>    filesystem_type       = optional(string, "ext4")<br/>  }))</pre> | `[]` | no |
| <a name="input_additional_iam_policy_arns"></a> [additional\_iam\_policy\_arns](#input\_additional\_iam\_policy\_arns) | List of additional IAM policy ARNs to attach to the instance role.<br/>Useful for granting instances access to AWS services like S3, DynamoDB, etc.<br/>Example: ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"] | `list(string)` | `[]` | no |
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | List of additional security group IDs to attach to the instances.<br/>This allows attaching custom security groups (e.g., for HTTP, HTTPS, or application-specific rules)<br/>alongside the module's default SSH security group.<br/>Example: ["sg-12345678", "sg-87654321"] | `list(string)` | `[]` | no |
| <a name="input_allow_ssh_ips"></a> [allow\_ssh\_ips](#input\_allow\_ssh\_ips) | List IP address that will be allowed to SSH into the box.<br/>Format is "123.123.123.123/32" | `list(string)` | <pre>[<br/>  "192.168.1.1/32"<br/>]</pre> | no |
| <a name="input_allow_ssh_ipv6_ips"></a> [allow\_ssh\_ipv6\_ips](#input\_allow\_ssh\_ipv6\_ips) | List of IPv6 addresses that will be allowed to SSH into the box.<br/>Format is "2001:db8::1/128" for single addresses or "2001:db8::/64" for ranges.<br/>If empty, no IPv6 SSH access will be allowed. | `list(string)` | `[]` | no |
| <a name="input_custom_ami_id"></a> [custom\_ami\_id](#input\_custom\_ami\_id) | Custom AMI ID to use for the instances instead of automatic OS family selection.<br/>When specified, this overrides the os\_family automatic AMI selection.<br/>Useful for using golden images, hardened AMIs, or specific AMI versions.<br/>Example: "ami-0123456789abcdef0" | `string` | `null` | no |
| <a name="input_custom_bootstrap_script"></a> [custom\_bootstrap\_script](#input\_custom\_bootstrap\_script) | Path to a custom bootstrap script relative to the root module (where you invoke this module).<br/>If provided, this will be used instead of the default bootstrap script.<br/>Use path.root in your module invocation, e.g., "${path.root}/scripts/custom-bootstrap.sh" | `string` | `""` | no |
| <a name="input_custom_cloud_config"></a> [custom\_cloud\_config](#input\_custom\_cloud\_config) | Path to a custom cloud-config YAML file relative to the root module (where you invoke this module).<br/>If provided, this will be used instead of the default cloud-config.<br/>Use path.root in your module invocation, e.g., "${path.root}/config/custom-cloud-config.yaml" | `string` | `""` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | Enable IPv6 address assignment for EC2 instances.<br/>When enabled, each instance will be assigned an IPv6 address.<br/><br/>IMPORTANT: For IPv6 to work properly, your VPC must have:<br/>1. An IPv6 CIDR block assigned to the VPC<br/>2. An IPv6 CIDR block assigned to the subnet<br/>3. An Internet Gateway (IGW) or Egress-Only Internet Gateway attached<br/>4. Route table with IPv6 routes (::/0 -> IGW or Egress-Only IGW)<br/><br/>If IPv6 is enabled but routing is not properly configured, you may experience:<br/>- NAT64 synthetic addresses (64:ff9b::/96) that don't work<br/>- DNS timeouts when trying to reach external services<br/>- SSH/Git operations failing after 30-60 second timeouts<br/><br/>Recommended: Set to false unless you have confirmed IPv6 routing is working. | `bool` | `false` | no |
| <a name="input_enable_ipv6_security_rules"></a> [enable\_ipv6\_security\_rules](#input\_enable\_ipv6\_security\_rules) | Enable IPv6 security group rules for ingress/egress traffic.<br/>When enabled, allows:<br/>- IPv6 SSH access (if allow\_ssh\_ipv6\_ips is configured)<br/>- IPv6 high ports (10000-65535) for return traffic and applications<br/>- IPv6 egress to ::/0 (all outbound traffic)<br/><br/>Blocks all incoming IPv6 traffic on ports below 10000 (except SSH if configured).<br/><br/>Set to false if you want to use IPv4-only communication or if your VPC doesn't have proper IPv6 routing. | `bool` | `false` | no |
| <a name="input_enable_ssm"></a> [enable\_ssm](#input\_enable\_ssm) | If true, enables AWS Systems Manager (SSM) Session Manager for connecting to instances.<br/>This controls both:<br/>- Installation of the SSM agent during instance bootstrap<br/>- Attachment of the AmazonSSMManagedInstanceCore IAM policy to the instance role<br/>Set to false to skip SSM agent installation and save on bootstrap time if you only need SSH access. | `bool` | `true` | no |
| <a name="input_instances"></a> [instances](#input\_instances) | List of instances to create.<br/>Example:<br/>[<br/>  {<br/>    name                    = "instance1.example.com"<br/>    instance\_type           = "t3.micro"<br/>    disable\_api\_termination = false<br/>    volume\_size             = 10<br/>    public                  = true<br/>  },<br/>  {<br/>    name                    = "instance2.example.com"<br/>    instance\_type           = "t3.large"<br/>    disable\_api\_termination = false<br/>    volume\_size             = 20<br/>    public                  = false<br/>  }<br/>] | <pre>list(object({<br/>    name                    = string<br/>    instance_type           = string<br/>    disable_api_termination = bool<br/>    volume_size             = number<br/>    public                  = bool<br/>    }<br/>  ))</pre> | n/a | yes |
| <a name="input_ipv6_address_count"></a> [ipv6\_address\_count](#input\_ipv6\_address\_count) | Number of IPv6 addresses to assign to each instance.<br/>Only used when enable\_ipv6 is true.<br/>Typical values: 1 (for a single IPv6 address per instance) | `number` | `1` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the instance group.<br/>Used as a prefix for IAM roles, security groups, and other resources. | `string` | n/a | yes |
| <a name="input_os_arch"></a> [os\_arch](#input\_os\_arch) | Processor architecture, possible options:<br/>- amd64<br/>- arm64 | `string` | `"amd64"` | no |
| <a name="input_os_family"></a> [os\_family](#input\_os\_family) | The flavor for the EC2 instance to be deployed, possible options:<br/>  - debian<br/>  - ubuntu<br/>  - freebsd<br/>  - flatcar | `string` | `"debian"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where the AWS provider will be configured and deployed | `string` | `"us-east-1"` | no |
| <a name="input_route53_hosted_zone_id"></a> [route53\_hosted\_zone\_id](#input\_route53\_hosted\_zone\_id) | Route53 hosted zone ID where DNS records will be created.<br/>If specified along with route53\_subdomains, A records will be created pointing to the instance's public IP if it has one, its private IP otherwise. | `string` | `null` | no |
| <a name="input_route53_subdomains"></a> [route53\_subdomains](#input\_route53\_subdomains) | List of subdomain names to create as A records in the specified Route53 hosted zone.<br/>Only used when route53\_hosted\_zone\_id is specified.<br/>Example: ["app", "api", "www"] | `list(string)` | `[]` | no |
| <a name="input_root_volume_encrypted"></a> [root\_volume\_encrypted](#input\_root\_volume\_encrypted) | If true, the root EBS volume will be encrypted | `bool` | `true` | no |
| <a name="input_root_volume_kms_key_id"></a> [root\_volume\_kms\_key\_id](#input\_root\_volume\_kms\_key\_id) | KMS key ID to use for root volume encryption.<br/>If not specified, the default AWS EBS encryption key will be used.<br/>Only applies when root\_volume\_encrypted is true. | `string` | `null` | no |
| <a name="input_spot_enabled"></a> [spot\_enabled](#input\_spot\_enabled) | If true, the instance will be a spot-instance | `bool` | `false` | no |
| <a name="input_spot_price"></a> [spot\_price](#input\_spot\_price) | The maximum hourly price you're willing to pay for a Spot Instance. Defaults to null (no cap — AWS uses the On-Demand price as the implicit ceiling). | `number` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet where the resources will be created | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC where the resources will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ami_id"></a> [ami\_id](#output\_ami\_id) | ID of the AMI used for the instances |
| <a name="output_ebs_volume_arns"></a> [ebs\_volume\_arns](#output\_ebs\_volume\_arns) | Map of additional EBS volume ARNs (key format: instance\_name-volN) |
| <a name="output_ebs_volume_ids"></a> [ebs\_volume\_ids](#output\_ebs\_volume\_ids) | Map of additional EBS volume IDs (key format: instance\_name-volN) |
| <a name="output_iam_instance_profile_name"></a> [iam\_instance\_profile\_name](#output\_iam\_instance\_profile\_name) | Name of the IAM instance profile attached to the instances |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the IAM role attached to the instances |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the IAM role attached to the instances |
| <a name="output_instance_arns"></a> [instance\_arns](#output\_instance\_arns) | Map of instance ARNs |
| <a name="output_instance_info"></a> [instance\_info](#output\_instance\_info) | Map of instance information including IDs, IP addresses, and instance types for all created instances |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group attached to the instances |
<!-- END_TF_DOCS -->
