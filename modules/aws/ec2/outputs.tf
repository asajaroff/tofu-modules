output "instance_info" {
  description = "Map of instance information including IDs, IP addresses, and instance types for all created instances"
  value = {
    for instance_id, instance in aws_instance.this :
    instance_id => {
      id             = instance.id
      public_ip      = instance.public_ip
      private_ip     = instance.private_ip
      ipv6_addresses = instance.ipv6_addresses
      instance_type  = instance.instance_type
    }
  }
}

output "security_group_id" {
  description = "ID of the security group attached to the instances"
  value       = aws_security_group.instance.id
}

output "iam_role_name" {
  description = "Name of the IAM role attached to the instances"
  value       = aws_iam_role.this.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role attached to the instances"
  value       = aws_iam_role.this.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile attached to the instances"
  value       = aws_iam_instance_profile.this.name
}

output "ami_id" {
  description = "ID of the AMI used for the instances"
  value       = local.selected_ami
}

output "instance_arns" {
  description = "Map of instance ARNs"
  value = {
    for instance_id, instance in aws_instance.this :
    instance_id => instance.arn
  }
}

output "ebs_volume_ids" {
  description = "Map of additional EBS volume IDs (key format: instance_name-volN)"
  value = {
    for key, vol in aws_ebs_volume.additional :
    key => vol.id
  }
}

output "ebs_volume_arns" {
  description = "Map of additional EBS volume ARNs (key format: instance_name-volN)"
  value = {
    for key, vol in aws_ebs_volume.additional :
    key => vol.arn
  }
}
