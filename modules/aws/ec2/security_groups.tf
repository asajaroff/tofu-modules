# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "instance" {
  name        = "${var.name}-sg"
  description = "Security group for EC2 instances"
  vpc_id      = data.aws_vpc.selected.id

  tags = merge(
    { Name = "${var.name}-sg" },
    var.tags
  )
}

# SSH access from IPv4 addresses
resource "aws_vpc_security_group_ingress_rule" "ssh_ipv4" {
  for_each = toset(var.allow_ssh_ips)

  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = each.value
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# SSH access from IPv6 addresses
resource "aws_vpc_security_group_ingress_rule" "ssh_ipv6" {
  for_each = var.enable_ipv6_security_rules ? toset(var.allow_ssh_ipv6_ips) : []

  security_group_id = aws_security_group.instance.id
  cidr_ipv6         = each.value
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Allow high ports for IPv6 - ports 10000+ for return traffic and application ports
resource "aws_vpc_security_group_ingress_rule" "high_ports_tcp_ipv6" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv6         = "::/0"
  from_port         = 10000
  ip_protocol       = "tcp"
  to_port           = 65535

  lifecycle {
    enabled = var.enable_ipv6_security_rules
  }
}

resource "aws_vpc_security_group_ingress_rule" "high_ports_udp_ipv6" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv6         = "::/0"
  from_port         = 10000
  ip_protocol       = "udp"
  to_port           = 65535

  lifecycle {
    enabled = var.enable_ipv6_security_rules
  }
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "all_ipv6" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"

  lifecycle {
    enabled = var.enable_ipv6_security_rules
  }
}


# Places to get the IP address from
# dig +short txt ch whoami.cloudflare @1.0.0.1
# dig +short myip.opendns.com @resolver1.opendns.com
# dig TXT +short o-o.myaddr.l.google.com @ns1.google.com
