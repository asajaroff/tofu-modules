# Agent Instructions for EC2 Module

This document provides context and guidelines for AI agents (like Claude) working with this OpenTofu/Terraform EC2 module.

## Module Overview

This is a flexible EC2 module for provisioning AWS instances with support for:
- Multiple OS families (Debian, Ubuntu, FreeBSD, Flatcar Container Linux)
- Multiple architectures (amd64, arm64)
- Spot instances (no price cap by default — see `variables.tf`'s `spot_price`)
- IAM role/profile integration
- AWS SSM (Session Manager) support
- Cloud-init based configuration (per-OS defaults, or fully custom via `custom_bootstrap_script`/`custom_cloud_config`)
- Security group management with SSH access control
- Additional EBS volumes (auto-formatted/mounted)
- Optional Route53 A records per subdomain

**No SSH key management of any kind.** A past version auto-generated key pairs (`create_ssh_key`/`ssh_key_name` variables, a `private_key`/`key_pair_name` output); that feature was removed. If you see any of those four names anywhere (code, docs, an old example), that's leftover staleness to fix, not something to preserve.

## File Structure

```
modules/aws/ec2/
├── main.tf              # Core aws_instance resource (for_each over `instances`)
├── variables.tf         # Input variable definitions
├── outputs.tf           # Output definitions
├── data.tf              # AMI selection (one aws_ami data source per os_family, each
│                         # count-gated so only the selected family is ever evaluated —
│                         # see git history for why: an unconditional lookup for an
│                         # unselected family breaks in regions where it isn't published)
├── iam.tf                # IAM role, instance profile, policy attachments
├── ebs.tf               # Additional EBS volumes + attachments
├── route53.tf           # Optional Route53 A records
├── security_groups.tf   # Security group and SSH ingress rules
├── cloudinit.tf         # Per-OS cloudinit_config composition
├── provider.tf          # required_providers only — no `provider "aws" {}` block
│                         # (a module with its own provider config can't be called
│                         # with count/for_each/depends_on by its caller — keep it that way)
├── config/              # Default bootstrap scripts + cloud-config per OS family
├── examples/custom-cloud-init/  # Full example of custom_bootstrap_script/custom_cloud_config
├── README.md            # User-facing documentation (has a terraform-docs generated
│                         # block between <!-- BEGIN_TF_DOCS --> / END_TF_DOCS — when you
│                         # add/remove/rename a variable or output, that block goes stale
│                         # unless you update it too; there's no CI check for this)
└── CHANGELOG.md          # Keep a Changelog format
```

There is no `TODO.md` and no `CODE_NOTES.md` — earlier versions of this file referenced both; if either reappears, verify it's actually current before trusting it (this module has a history of these tracking docs drifting from the code — see git log for `AGENTS.md`/`CODE_NOTES.md` if curious).

## Key Design Patterns

### Instance Management
- Uses `for_each` over `var.instances`, keyed by each instance's `name` — **not** the AWS instance ID.
- `instance_info` output is likewise keyed by that same logical `name`.
- Changing an instance's `name` in the list forces destroy+recreate of that instance (it's the for_each key).
- All instances in one module call share: one `subnet_id`, one security group, one IAM role, and (if set) one `custom_cloud_config`/`custom_bootstrap_script`. There is no per-instance override for any of these — a consumer needing different subnets/AZs or different boot behavior per instance needs separate module calls, one per group that needs to differ.

### AMI Selection
- One `aws_ami` data source per `os_family`, each gated by `count = var.custom_ami_id == null && var.os_family == "<family>" ? 1 : 0` — only the selected family's data source ever runs.
- `custom_ami_id` bypasses AMI lookup entirely when set.

### Cloud-init
- `custom_cloud_config`/`custom_bootstrap_script` are read via plain `file()` — **not** `templatefile()`. No per-cluster or per-instance variable injection is possible through these. A consumer needing dynamic values in cloud-init has to discover them at boot instead (e.g. via instance tags + IMDS, or SSM Parameter Store) — see `modules/aws/k3s`'s `config/*.yaml` for a real example of this pattern.
- Default scripts/configs live in `config/`, one pair per `os_family`.

### Security Model
- IMDSv2 enforced (`http_tokens = "required"`).
- Security group allows SSH only from `allow_ssh_ips`/`allow_ssh_ipv6_ips`; egress is unrestricted.
- No `instance_metadata_tags` support — a consumer can't have an instance read its own tags via IMDS; it has to call `ec2:DescribeTags` instead (real friction point, see `modules/aws/k3s`).

### IAM Configuration
- One shared `aws_iam_role`/`aws_iam_instance_profile` per module call, named from `var.name`.
- `additional_iam_policy_arns` is a `list(string)` attached via `for_each` over an **index-keyed map** (`{ for idx, arn in var.additional_iam_policy_arns : tostring(idx) => arn }`), not `toset()`. Keep it that way — `toset()` on a list containing a not-yet-known value (e.g. a policy ARN from a resource created in the same apply) fails outright; indexing works because the list's length is statically known even when its elements aren't.

## Testing and Validation

There is no `tofu test` suite. Before tagging any change:
```bash
cd modules/aws/ec2
tofu fmt -check -recursive -diff .
tofu init -backend=false && tofu validate
```
`validate` alone won't catch everything — three real bugs shipped in prior tags precisely because `validate` passed but a live `plan`/`apply` didn't: an unconditional AMI lookup failing in a region without that OS family's AMI, the module's own `provider {}` block rejecting `for_each` from a caller, and `toset()` rejecting a not-yet-known ARN. When changing anything in `data.tf`, `iam.tf`, `provider.tf`, or `cloudinit.tf`, do a real `tofu plan` against actual AWS data if at all possible, not just `validate`.

## Versioning

Tags follow `ec2/vX.Y.Z` (the current convention — some very old tags used a `ec2-vX.Y.Z` hyphen form; ignore those). `main` is branch-protected — land changes via PR, not a direct push. Update `CHANGELOG.md`'s `[Unreleased]` section for every change, and prune it (move to a version heading) when you cut a tag — it has a history of accumulating entries for features that were later changed or removed entirely.
