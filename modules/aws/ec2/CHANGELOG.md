# Changelog

All notable changes to the EC2 module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Removed
- Removed SSH key management entirely (`create_ssh_key`/`ssh_key_name` variables, `private_key`/`key_pair_name` outputs, `keys.tf`) — this had already happened in an untagged/unlogged commit at some point after `[1.0.1]` below; recording it now since docs and examples still referenced the removed variables/outputs until this pass fixed them. Use SSM (`enable_ssm`) or embed a key yourself via `custom_cloud_config`.

### Fixed
- `ec2/v1.2.1`: gated each `aws_ami` data source with `count` keyed on `os_family`, so an unselected family's AMI lookup failing/being unpublished in the current region (e.g. `freebsd` in `eu-central-1`) no longer breaks every plan
- `ec2/v1.2.2`: removed the module's own `provider "aws" {}` block — Terraform rejects calling a module with such a block via `count`/`for_each`/`depends_on`
- `ec2/v1.2.3`: `additional_iam_policy_arns` now indexes into the list instead of `toset()`, so attaching a policy created in the same apply (its ARN "known after apply") no longer fails
- `spot_price` default changed from `0.005` (unrealistically low for any current instance type — a spot request capped there will never fulfill) to `null` (no cap, AWS uses the On-Demand price as the ceiling)
- `route53_subdomains` A records now use the instance's private IP when it has no public one, instead of writing an empty/broken record
- Resolved conflicting version-pin files (`.tofu-version` said `v1.10.6`, `.opentofu-version` said `1.10.7`) — kept `.opentofu-version` as the single source of truth, removed `.tofu-version`

### Documentation
- Rewrote `AGENTS.md` — the previous version described `instances_map`, `pool_name`, `aws_ssm_enabled`, `create_key`, and a `TODO.md` that doesn't exist
- Deleted `CODE_NOTES.md` — described issues already fixed (hardcoded spot price, Debian-only cloud-init) as still open, and referenced the same removed variable names as `AGENTS.md`
- Fixed `README.md` and `examples/custom-cloud-init/` to stop referencing the removed SSH key variables/outputs, fixed an `instance_info` indexing example that assumed ID-keying (it's keyed by the logical `name`), fixed `allow_ssh_ips = ["0.0.0.0/0"]` in the example to a documentation-safe placeholder, added the missing `route53_*` input/output rows and removed the dead `tls` requirement from the generated docs block

## [Unreleased, pre-1.2.x] — multiple untagged/undocumented releases folded into one entry

The entries below accumulated here across what was actually several real tags (`ec2/v1.1.x` through `ec2/v1.2.0`) without ever being moved to a version heading at release time, so the version boundaries for individual items are no longer reconstructable. Treat this block as a historical summary, not a precise per-version record — going forward, every tag in this file's own [Unreleased] section above gets its own line, and this section doesn't grow further.

### Added
- Added AGENTS.md with instructions for AI assistants working with this module
- Added CODE_NOTES.md with comprehensive code improvements, problems, and notable changes reference
- Added comprehensive TODO.md documenting known issues and planned improvements
- Added cloud-init configurations for Ubuntu (`bootstrap-ubuntu.sh`, `cloud-config-ubuntu.yaml`)
- Added cloud-init configurations for FreeBSD (`bootstrap-freebsd.sh`, `cloud-config-freebsd.yaml`)
- Added cloud-init configurations for Flatcar Container Linux (`bootstrap-flatcar.sh`, `cloud-config-flatcar.yaml`)
- Added support for Flatcar Container Linux as a new `os_family` option
- Added Flatcar AMI data source using official Flatcar owner ID (075585003325)
- Added architecture-aware AMI filtering for Flatcar (x86_64/arm64)
- Added container-based SSM agent deployment for Flatcar instances
- Added 7 new outputs for better module integration:
  - `security_group_id` - ID of the SSH security group
  - `iam_role_name` - Name of the IAM role
  - `iam_role_arn` - ARN of the IAM role
  - `iam_instance_profile_name` - Name of the IAM instance profile
  - `key_pair_name` - Name of the SSH key pair (or null)
  - `ami_id` - ID of the selected AMI
  - `instance_arns` - Map of instance ARNs
- Added `allow_ssh_ipv6_ips` variable for IPv6 SSH access control with default empty list (no IPv6 SSH by default)
- Added IPv6 SSH security group rules that iterate over custom addresses (consistent with IPv4 pattern)
- Added `disable_api_termination` implementation to EC2 instances (was defined in variables but not applied)
- Added tags to IAM role, IAM instance profile, SSH key pair, and security group for better resource management
- Added map-based AMI selection logic for cleaner code (`ami_map` in data.tf)
- Added map-based cloudinit selection logic for cleaner code (`cloudinit_map` in cloudinit.tf)
- Added `additional_security_group_ids` variable for attaching custom security groups alongside default SSH group
- Added `additional_iam_policy_arns` variable for attaching custom IAM policies to instance role
- Added `root_volume_encrypted` variable (default: true) for root volume encryption
- Added `root_volume_kms_key_id` variable for specifying custom KMS key for root volume encryption
- Added `custom_ami_id` variable to override automatic AMI selection with custom/golden images
- Added `additional_ebs_volumes` variable for attaching and auto-mounting additional EBS volumes
- Added automatic EBS volume formatting, mounting, and /etc/fstab management via cloud-init
- Added `ebs_volume_ids` and `ebs_volume_arns` outputs for additional EBS volumes
- Added subnet data source for retrieving availability zone information
- Created `ebs.tf` with EBS volume and attachment resources
- Created `config/mount-ebs.sh.tpl` template for automatic EBS volume mounting

### Changed - BREAKING
- **BREAKING**: Renamed `pool_name` variable to `name` for clearer purpose and simpler naming
- **BREAKING**: Renamed `instances_map` variable to `instances` (it was always a list, not a map)
- **BREAKING**: Renamed `create_key` variable to `create_ssh_key` for consistency and clarity
- **BREAKING**: Renamed `aws_ssm_enabled` variable to `enable_ssm` for consistent naming pattern
- **BREAKING**: Renamed `key_name` variable to `ssh_key_name` for specificity
- **BREAKING**: Removed unused `associate_public_ip_address` variable (functionality already available via `instances[].public`)
- **BREAKING**: Changed IPv6 SSH access from open `::/0` to custom list via `allow_ssh_ipv6_ips` (secure by default)
- **BREAKING**: Renamed `key_pair_name` output to `ssh_key_name` for consistency
- **BREAKING**: Renamed security group resource from `allow_ssh` to `instance` (reflects broader purpose)

### Changed - Non-Breaking
- Changed security group naming to use `pool_name` for uniqueness and multi-module deployment support
- Changed `allow_ssh_ip` (string) to `allow_ssh_ips` (list) to support multiple IP addresses
- Removed unused `local-exec` provisioner with `dig` command from security group
- Standardized all resource naming to use hyphens consistently
- Improved security group resource naming:
  - `allow_ssh_ipv4` → `ssh_ipv4`
  - `allow_ssh_ipv6` → `ssh_ipv6`
  - `allow_high_ports_ipv6` → `high_ports_tcp_ipv6`
  - `allow_high_ports_udp_ipv6` → `high_ports_udp_ipv6`
  - `allow_all_traffic_ipv4` → `all_ipv4`
  - `allow_all_traffic_ipv6` → `all_ipv6`
- Improved security group description from "Allow SSH inbound traffic..." to "Security group for EC2 instances"
- Improved security group naming from `${var.name}-ssh-ingress` to `${var.name}-sg`
- Improved IAM resource naming:
  - Instance profile: `${var.name}-iam-instance-profile` → `${var.name}-instance-profile`
  - Policy attachment: `custom` → `ssm` (clearer purpose)
- Simplified AMI selection logic from nested ternaries to map lookup for better readability
- Simplified cloudinit selection logic from nested ternaries to map lookup for better readability
- Improved comments in iam.tf for clarity (e.g., "Attach SSM policy to role for Session Manager access")
- Standardized boolean checks (removed redundant `== true` comparisons)
- Changed empty string returns to `null` for optional values (e.g., `key_name` when SSH key not created)
- Updated main.tf tags format from single-line to multi-line for better readability
- Improved default value for `ssh_key_name` from verbose string to concise "terraform-ec2-module-key"

### Fixed
- Fixed key pair conditional creation - now properly respects `create_key` variable
- Fixed spot instance `instance_interruption_behavior` - added missing quotes to `"stop"` value
- Fixed `private_key` output to return null when `create_key` is false (prevents errors)
- Fixed key pair reference to use index `[0]` for conditional resource
- Fixed spot instance pricing - now uses `var.spot_price` instead of hardcoded `0.005`
- Fixed cloud-init configuration - now conditional based on `os_family` (Debian, Ubuntu, or FreeBSD)
- Fixed IAM SSM policy attachment - now conditional based on `aws_ssm_enabled` variable
- Fixed security group name - removed space, now uses `${var.pool_name}-ssh-ingress`
- Fixed security group tag naming - standardized to use hyphens `${var.pool_name}-ssh`
- Fixed variable types - `spot_enabled` and `aws_ssm_enabled` changed from `string` to `bool`
- Fixed `key_name` variable description to clarify it's the SSH key pair name
- Fixed `disable_api_termination` - now actually applied to instances (was only defined in variables)
- Fixed inconsistent output descriptions to reference new variable names

### Improved
- Improved README.md documentation with all new variable names and examples
- Improved variable descriptions for clarity and consistency
- Improved output descriptions for accuracy
- Updated all examples in `examples/custom-cloud-init/` with new variable names
- Updated architecture diagrams to reflect new naming conventions
- Improved code organization and readability throughout module
- Improved custom cloud-config documentation for consistency

### Security
- **SECURITY**: Changed default IPv6 SSH behavior from open (`::/0`) to closed (empty list) - must explicitly allow IPv6 addresses
- **SECURITY**: IPv6 SSH now requires explicit address whitelisting via `allow_ssh_ipv6_ips` variable
- **SECURITY**: Root volume encryption now enabled by default (`root_volume_encrypted = true`)

### Verified
- Verified Debian 13 (Trixie) AMI availability and naming pattern compatibility

## [1.0.1] - 2025-10-12

### Added
- Re-added `private_key` output for SSH access
- Added comprehensive TODO documentation

### Changed
- Improved README with better examples and documentation
- Refactored module structure for better maintainability

## [1.0.0] - 2024-09-22

### Added
- Initial EC2 module release
- Support for multiple operating systems (Debian, Ubuntu, FreeBSD)
- Support for multiple architectures (amd64, arm64)
- Spot instance support with configurable pricing
- Automated SSH key pair generation and management
- IAM role and instance profile creation
- AWS Session Manager (SSM) integration
- Cloud-init based instance initialization
- Security group management with SSH access control
- Configurable root volume size per instance
- Multi-instance deployment from single module call
- IMDSv2 enforcement for enhanced security
- Support for public and private instances

### Fixed
- Fixed variable type for `public` field in `instances_map` from hardcoded `true` to proper `bool`
- Fixed example documentation with correct instance names and volume_size

## [0.1.0] - 2024-09-01 (Initial Development)

### Added
- Basic EC2 instance provisioning
- AMI selection logic for different OS families
- Basic security group configuration
- Instance profile integration
- Cloud-init configuration for Debian
- Makefile for common operations
- Initial documentation

[Unreleased]: https://github.com/asajaroff/tofu-modules/compare/ec2-v1.0.1...HEAD
[1.0.1]: https://github.com/asajaroff/tofu-modules/compare/ec2-v1.0.0...ec2-v1.0.1
[1.0.0]: https://github.com/asajaroff/tofu-modules/releases/tag/ec2-v1.0.0
