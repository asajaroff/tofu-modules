# Route53 DNS records for instances
# Creates A records for each subdomain pointing to the instance's public IP

locals {
  # Create a flat list of all subdomain-instance combinations
  route53_records = var.route53_hosted_zone_id != null ? flatten([
    for subdomain in var.route53_subdomains : [
      for instance_name, instance in aws_instance.this : {
        key         = "${subdomain}-${instance_name}"
        subdomain   = subdomain
        instance_id = instance.id
        public_ip   = instance.public_ip
      }
    ]
  ]) : []
}

resource "aws_route53_record" "subdomains" {
  for_each = { for record in local.route53_records : record.key => record }

  zone_id = var.route53_hosted_zone_id
  name    = each.value.subdomain
  type    = "A"
  ttl     = 300
  records = [each.value.public_ip]
}
