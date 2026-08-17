# Custom Cloud-Init Scripts Example

This example demonstrates how to use custom cloud-init scripts with the EC2 module instead of the default bootstrap scripts and cloud-config files.

## Overview

The EC2 module supports two ways to configure cloud-init:

1. **Default scripts** - Use the pre-configured scripts included with the module
2. **Custom scripts** - Provide your own bootstrap script and cloud-config file (demonstrated here)

## Files in This Example

```
custom-cloud-init/
├── README.md                    # This file
├── main.tf                      # Terraform configuration using custom scripts
├── variables.tf                 # Input variables
├── bootstrap-custom.sh          # Custom bootstrap shell script
└── cloud-config-custom.yaml     # Custom cloud-config YAML file
```

## What's the Difference Between Bootstrap Script and Cloud-Config?

### Bootstrap Script (`bootstrap-custom.sh`)
- **Runs first**, before cloud-init processes the cloud-config
- Written as a shell script (bash/sh)
- Best for:
  - Installing system agents (AWS SSM, monitoring agents, etc.)
  - Architecture-specific installations
  - Setting up custom repositories
  - Low-level system configuration
  - Tasks that need to run before package installation

### Cloud-Config (`cloud-config-custom.yaml`)
- **Runs second**, after the bootstrap script
- Written in YAML format (cloud-init syntax)
- Best for:
  - Installing packages via package manager
  - Creating users and managing SSH keys
  - Writing files to the filesystem
  - Running commands after packages are installed
  - Higher-level system configuration

## How to Use This Example

### Step 1: Customize the Scripts

1. **Edit `bootstrap-custom.sh`**:
   - Modify or comment out the SSM agent installation if you don't need it
   - Add any custom system-level setup you need
   - Ensure the script is executable (the module handles this automatically)

2. **Edit `cloud-config-custom.yaml`**:
   - Replace the example SSH keys with your own public keys
   - Modify the package list to include what you need
   - Customize the `write_files` section to create your own files
   - Add custom commands in the `runcmd` section

### Step 2: Configure Terraform Variables

Create a `terraform.tfvars` file in this directory:

```hcl
region    = "us-east-1"
vpc_id    = "vpc-xxxxxxxxxxxxx"
subnet_id = "subnet-xxxxxxxxxxxxx"
```

Or export environment variables:

```bash
export TF_VAR_region="us-east-1"
export TF_VAR_vpc_id="vpc-xxxxxxxxxxxxx"
export TF_VAR_subnet_id="subnet-xxxxxxxxxxxxx"
```

### Step 3: Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# When done, clean up
terraform destroy
```

### Step 4: Access Your Instance

The module has no built-in SSH key management — `instance_info` (keyed by AWS instance ID) is the source of truth for IDs/IPs either way.

**AWS Session Manager (if `enable_ssm = true`, as in this example) — needs no key at all:**
```bash
# Get the instance ID (instance_info is a map keyed by instance ID)
INSTANCE_ID=$(terraform output -json instance_info | jq -r 'keys[0]')

# Connect via SSM
aws ssm start-session --target $INSTANCE_ID
```

**SSH:**
Only works if `cloud-config-custom.yaml` embeds a public key (see its `ssh_authorized_keys`/`users` section) — the module itself never generates or manages one.
```bash
PUBLIC_IP=$(terraform output -json instance_info | jq -r '.[].public_ip')

# user depends on OS: admin for Debian, ubuntu for Ubuntu
ssh admin@$PUBLIC_IP
```

### Step 5: Verify Cloud-Init

Once connected to your instance, verify cloud-init ran successfully:

```bash
# Check cloud-init status
cloud-init status

# View cloud-init logs
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log

# View your custom log (if you used the example runcmd)
sudo cat /var/log/cloud-init-custom.log

# View all logs
sudo journalctl -u cloud-init
```

## Module Variables Reference

The key variables for custom cloud-init are:

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `custom_bootstrap_script` | string | No | Path to custom bootstrap script (relative to root module) |
| `custom_cloud_config` | string | No | Path to custom cloud-config YAML (relative to root module) |

**Important Notes:**
- Use `${path.root}` to reference files relative to where you run `terraform apply`
- If these variables are not provided (or set to empty string), the module uses default scripts
- Both variables must point to valid files if specified
- The paths are evaluated at Terraform plan time

## Using These Scripts in Your Own Project

To use custom cloud-init in your own Terraform project:

1. **Copy the example scripts to your project:**
   ```bash
   mkdir -p scripts
   cp bootstrap-custom.sh scripts/
   cp cloud-config-custom.yaml scripts/
   ```

2. **Customize them for your needs**

3. **Reference them in your module call:**
   ```hcl
   module "my_ec2" {
     source = "path/to/modules/ec2"

     # ... other variables ...

     custom_bootstrap_script = "${path.root}/scripts/bootstrap-custom.sh"
     custom_cloud_config     = "${path.root}/scripts/cloud-config-custom.yaml"
   }
   ```

## Common Use Cases

### Use Case 1: Custom Application Deployment
Create a cloud-config that:
- Installs your application dependencies
- Clones your application repository
- Sets up systemd services
- Configures monitoring

### Use Case 2: Development Environment
Create scripts that:
- Install development tools (git, docker, etc.)
- Set up IDE or editor configurations
- Clone common repositories
- Create developer users with specific permissions

### Use Case 3: Hardened Security Configuration
Create scripts that:
- Install and configure security tools
- Set up firewall rules
- Configure audit logging
- Disable unnecessary services
- Apply CIS benchmarks

### Use Case 4: Container Host
Create scripts that:
- Install Docker or Podman
- Configure container runtime
- Set up container registries
- Deploy initial containers

## Troubleshooting

### Cloud-Init Didn't Run
Check:
```bash
# Is cloud-init installed?
cloud-init --version

# Check for errors
sudo cloud-init analyze show

# Force re-run (for testing)
sudo cloud-init clean
sudo cloud-init init
```

### Script Syntax Errors
```bash
# Validate YAML syntax
cloud-init devel schema --config-file /path/to/cloud-config-custom.yaml

# Check bootstrap script syntax
bash -n bootstrap-custom.sh
```

### File Not Found Errors
- Ensure paths use `${path.root}` not `${path.module}`
- Verify files exist before running `terraform plan`
- Check file permissions (scripts should be readable)

## Additional Resources

- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Cloud-Init Examples](https://cloudinit.readthedocs.io/en/latest/reference/examples.html)
- [AWS User Data Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [Cloud-Init Module Reference](https://cloudinit.readthedocs.io/en/latest/reference/modules.html)

## License

This example is part of the tofu-modules project.
