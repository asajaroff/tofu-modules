# Cloudfront + S3 static site hosting

**OpenTofu only as of v2.0.0.** `aws_s3_bucket_versioning.this` uses `lifecycle { enabled = ... }`, added in OpenTofu 1.11 with no Terraform equivalent — it fails to parse there, on any Terraform version. Pin `<= v1.0.0` if you need Terraform compatibility.

## Requirements
* A route53 Hosted Zone with the top level domain name of the site to deploy
* Resources for certificate manager and certificate manager validation must be in `us-east-1`

## Upload template site for testing

```bash
cd templates/
S3_BUCKET_NAME=bucket_name aws s3 sync ./ s3://${S3_BUCKET_NAME}/public/
```

## ToDo

* Trailing spaces in CloudFront Lambda@Edge

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.67.0 |
| <a name="provider_aws.acm"></a> [aws.acm](#provider\_aws.acm) | 5.67.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.site_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.cert_domains](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudfront_distribution.static_site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.pretty_urls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_access_control.static_site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_route53_record.site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.site_www](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.validation_records](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.site_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.site_bucket_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.site_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.cloudfront_oac_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be added to the resources created by this module | `map(string)` | <pre>{<br/>  "Environment": "Development",<br/>  "Terragrunt": "false"<br/>}</pre> | no |
| <a name="input_hosted_zone_domain_name"></a> [hosted\_zone\_domain\_name](#input\_hosted\_zone\_domain\_name) | Top level domain of the site, written with a trailing dot: "example.com." | `string` | `"example.com."` | no |
| <a name="input_is_prod"></a> [is\_prod](#input\_is\_prod) | If true, will enable Bucket Versioning and Bucket Logging. | `bool` | `false` | no |
| <a name="input_pretty_urls"></a> [pretty\_urls](#input\_pretty\_urls) | If true, will deploy a cloudfront function to generate pretty URLs.<br/>https://en.wikipedia.org/wiki/Clean_URL | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where the AWS provider will be configured and deployed | `string` | n/a | yes |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Name of the S3 bucket that will be created to store the static site content | `string` | `"bucket-name"` | no |
| <a name="input_s3_bucket_versioning"></a> [s3\_bucket\_versioning](#input\_s3\_bucket\_versioning) | Enable versioning on the S3 bucket | `bool` | n/a | yes |
| <a name="input_s3_origin_path"></a> [s3\_origin\_path](#input\_s3\_origin\_path) | None | `string` | `"/public"` | no |
| <a name="input_subdomain"></a> [subdomain](#input\_subdomain) | Subdomain of the site. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_distribution_domain_name"></a> [cloudfront\_distribution\_domain\_name](#output\_cloudfront\_distribution\_domain\_name) | Domain name for the CloudFront distribution |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront\_distribution\_id](#output\_cloudfront\_distribution\_id) | ID of the CloudFront distribution |
<!-- END_TF_DOCS -->
