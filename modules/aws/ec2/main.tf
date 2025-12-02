# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "this" {
  for_each                    = { for instance in var.instances : instance.name => instance }
  instance_type               = each.value.instance_type
  ami                         = local.selected_ami
  key_name                    = var.create_ssh_key ? aws_key_pair.this[0].key_name : (var.ssh_key_name != "" ? var.ssh_key_name : null)
  subnet_id                   = var.subnet_id
  associate_public_ip_address = each.value.public
  ipv6_address_count          = var.enable_ipv6 ? var.ipv6_address_count : 0
  user_data                   = local.selected_cloudinit
  iam_instance_profile        = aws_iam_instance_profile.this.name
  vpc_security_group_ids = concat(
    [aws_security_group.instance.id],
    var.additional_security_group_ids
  )
  disable_api_termination = each.value.disable_api_termination

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags["Name"]]
  }

  # Root block device configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = each.value.volume_size
    delete_on_termination = true
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.root_volume_kms_key_id
  }

  # Spot instance configuration
  dynamic "instance_market_options" {
    for_each = var.spot_enabled ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        max_price                      = var.spot_price
        instance_interruption_behavior = "stop"
      }
    }
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(
    { "Name" = each.value.name },
    var.tags
  )
}
