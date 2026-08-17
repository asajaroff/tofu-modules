# Module Catalog

Complete catalog of all OpenTofu/Terraform modules in this repository.

## Quick Navigation

- [AWS Modules](#aws-modules)
- [DigitalOcean Modules](#digitalocean-modules)
- [Azure Modules](#azure-modules)
- [GCP Modules](#gcp-modules)

## AWS Modules

### Compute

#### EC2 - Elastic Compute Cloud
**Status:** ✅ Production Ready
**Version:** v2.0.0
**Compatibility:** OpenTofu only as of v2.0.0 — uses the `enabled` meta-argument, which doesn't exist in Terraform's grammar at all and fails to parse there
**Path:** `modules/aws/ec2`

Comprehensive EC2 instance management with support for:
- Multiple instance types and configurations
- EBS volume management
- IAM role integration
- Security group configuration
- User data and cloud-init
- Tags and metadata
- Spot instances

No built-in SSH key management — use SSM (`enable_ssm`) or embed a key via `custom_cloud_config`.

**Usage:**
```hcl
module "ec2" {
  source = "git::https://github.com/asajaroff/tofu-modules.git//modules/aws/ec2?ref=ec2/v2.0.0"

  # Your configuration here
}
```

[View Documentation](./modules/aws/ec2/README.md)

---

#### EIP - Elastic IP Address
**Status:** ⚠️ Incomplete
**Version:** v1.0.0
**Path:** `modules/aws/eip`

Manages Elastic IP addresses for AWS resources.

**Note:** Module needs additional outputs and documentation before production use.

[View Documentation](./modules/aws/eip/README.md)

---

### Content Delivery

#### CloudFront + S3 Static Site
**Status:** ✅ Production Ready
**Version:** v2.0.0
**Compatibility:** OpenTofu only as of v2.0.0 — uses the `enabled` meta-argument, which doesn't exist in Terraform's grammar at all and fails to parse there
**Path:** `modules/aws/cloudfront-s3-static-site`

Complete solution for hosting static websites with:
- S3 bucket for static content
- CloudFront CDN distribution
- SSL/TLS certificate management (ACM)
- Route53 DNS integration
- Lambda@Edge for advanced features
- Origin access identity

**Usage:**
```hcl
module "static_site" {
  source = "git::https://github.com/asajaroff/tofu-modules.git//modules/aws/cloudfront-s3-static-site?ref=cloudfront-s3-static-site/v2.0.0"

  domain_name = "example.com"
  # Additional configuration
}
```

[View Documentation](./modules/aws/cloudfront-s3-static-site/README.md)

---

#### CDN - CloudFront Distribution
**Status:** 🔄 In Progress
**Path:** `modules/aws/cdn`

Standalone CloudFront distribution management.

[View Documentation](./modules/aws/cdn/README.md)

---

### Storage

#### S3 - Simple Storage Service
**Status:** 🔄 In Progress
**Path:** `modules/aws/s3`

S3 bucket management with support for:
- Versioning
- Lifecycle policies
- Access control
- Encryption

[View Documentation](./modules/aws/s3/README.md)

---

### Networking

#### Route53 - DNS Management
**Status:** ⚠️ Incomplete
**Path:** `modules/aws/route53`

DNS zone and record management for Route53.

**Note:** Missing outputs documentation.

[View Documentation](./modules/aws/route53/README.md)

---

### Security

#### ACM - AWS Certificate Manager
**Status:** ⚠️ Incomplete
**Path:** `modules/aws/acm`

SSL/TLS certificate provisioning and management.

**Note:** Minimal implementation, needs enhancement.

[View Documentation](./modules/aws/acm/README.md)

---

## DigitalOcean Modules

### Kubernetes

#### DigitalOcean Kubernetes (DOKS)
**Status:** ✅ Production Ready
**Version:** v1.0.0
**Path:** `modules/digitalocean/kubernetes`

Managed Kubernetes cluster with:
- Auto-scaling node pools
- Multiple node sizes
- HA control plane
- Integrated monitoring
- Helm chart examples (Prometheus, Minio, Gitea)

**Usage:**
```hcl
module "doks" {
  source = "git::https://github.com/asajaroff/tofu-modules.git//modules/digitalocean/kubernetes?ref=digitalocean/kubernetes/v1.0.0"

  cluster_name = "production"
  region = "nyc1"
  # Additional configuration
}
```

[View Documentation](./modules/digitalocean/kubernetes/README.md)

---

### Networking

#### VPC - Virtual Private Cloud
**Status:** ✅ Production Ready
**Version:** v1.0.0
**Path:** `modules/digitalocean/vpc`

VPC network configuration for DigitalOcean:
- Custom IP ranges
- Regional networking
- Resource isolation

**Usage:**
```hcl
module "vpc" {
  source = "git::https://github.com/asajaroff/tofu-modules.git//modules/digitalocean/vpc?ref=digitalocean/vpc/v1.0.0"

  name = "production-vpc"
  region = "nyc1"
  ip_range = "10.0.0.0/16"
}
```

[View Documentation](./modules/digitalocean/vpc/README.md)

---

## Azure Modules

**Status:** 📋 Planned

Azure modules are planned for future development. See the [roadmap](./docs/TODO.md#planned-azure-modules) for proposed modules.

Want to contribute? Check out [AGENTS.md](./AGENTS.md) for guidelines.

---

## GCP Modules

**Status:** 📋 Planned

GCP modules are planned for future development. See the [roadmap](./docs/TODO.md#planned-gcp-modules) for proposed modules.

Want to contribute? Check out [AGENTS.md](./AGENTS.md) for guidelines.

---

## Module Status Legend

- ✅ **Production Ready**: Fully functional, tested, and documented
- 🔄 **In Progress**: Partially implemented, not recommended for production
- ⚠️ **Incomplete**: Needs work before production use
- 📋 **Planned**: Not yet started, contributions welcome

## Using Modules

### With Terragrunt Catalog

Browse available modules:
```bash
terragrunt catalog https://github.com/asajaroff/tofu-modules
```

Scaffold a module:
```bash
terragrunt scaffold https://github.com/asajaroff/tofu-modules//modules/aws/ec2
```

### Direct Module Reference

Use specific version (recommended):
```hcl
module "example" {
  source = "git::https://github.com/asajaroff/tofu-modules.git//modules/<provider>/<module>?ref=<provider>/<module>/vX.Y.Z"
}
```

Use latest from main (not recommended for production):
```hcl
module "example" {
  source = "git::https://github.com/asajaroff/tofu-modules.git//modules/<provider>/<module>"
}
```

### Local Development

Clone and reference locally:
```bash
git clone https://github.com/asajaroff/tofu-modules.git
```

```hcl
module "example" {
  source = "../tofu-modules/modules/<provider>/<module>"
}
```

## Module Versions

All modules follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

See [TAGGING.md](./docs/TAGGING.md) for complete versioning guidelines.

## Finding the Right Module

### By Cloud Provider
- **AWS**: Most comprehensive, 7 modules (3 production-ready)
- **DigitalOcean**: 2 production-ready modules
- **Azure**: Coming soon
- **GCP**: Coming soon

### By Use Case
- **Static Website**: `aws/cloudfront-s3-static-site`
- **Virtual Machines**: `aws/ec2`
- **Kubernetes**: `digitalocean/kubernetes`
- **Networking**: `digitalocean/vpc`, `aws/route53`

### By Maturity
- **Production Ready** (4 modules): EC2, CloudFront-S3-Static-Site, DOKS, DO-VPC
- **In Progress** (2 modules): S3, CDN
- **Incomplete** (3 modules): EIP, Route53, ACM

## Contributing

Want to contribute a new module or improve an existing one?

1. Read [AGENTS.md](./AGENTS.md) - Contribution guidelines
2. Check [TODO.md](./docs/TODO.md) - Planned modules
3. Review [TAGGING.md](./docs/TAGGING.md) - Versioning standards
4. Follow [CI-CD.md](./docs/CI-CD.md) - Development workflow

## Support

- **Issues**: Report bugs or request features on [GitHub Issues](https://github.com/asajaroff/tofu-modules/issues)
- **Documentation**: Check module README files
- **Examples**: See module directories for example configurations

## License

See [LICENSE](./LICENSE) file for details.
