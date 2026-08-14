# The ec2 module's own security group only opens SSH — it has no mechanism to
# add extra rules within a single call, so cluster-internal traffic (etcd,
# the k3s API, flannel overlay, kubelet) needs its own SG here, attached to
# every node via additional_security_group_ids (the same extensibility hook
# juno/proxy's custom-security-groups.tf already use for a different port).
resource "aws_security_group" "cluster" {
  name        = "${var.name}-cluster"
  description = "Internal traffic between ${var.name} k3s nodes"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

locals {
  cluster_ingress_ports = {
    k3s-api       = { from = 6443, to = 6443, protocol = "tcp" }   # k3s server API
    etcd-client   = { from = 2379, to = 2380, protocol = "tcp" }   # embedded etcd peer/client
    flannel-vxlan = { from = 8472, to = 8472, protocol = "udp" }   # flannel overlay network
    kubelet       = { from = 10250, to = 10250, protocol = "tcp" } # kubelet metrics/exec/logs
  }
}

resource "aws_vpc_security_group_ingress_rule" "cluster_internal" {
  for_each = local.cluster_ingress_ports

  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.cluster.id # self-referencing: only members of this SG
  ip_protocol                  = each.value.protocol
  from_port                    = each.value.from
  to_port                      = each.value.to
  tags                         = var.tags
}

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.cluster.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = var.tags
}
