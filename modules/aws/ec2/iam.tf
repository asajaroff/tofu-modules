# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "this" {
  name = "${var.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

# Attach SSM policy to role for Session Manager access
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach additional IAM policies to role
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
#
# for_each over an index-keyed map (not toset(var.additional_iam_policy_arns))
# on purpose: toset() requires every element to be fully known at plan time,
# which breaks the common case of attaching a policy created in the same
# apply (e.g. a policy resource whose .arn is "known after apply"). The list
# itself has a statically known length even when its elements don't, so
# indexing into it keeps the for_each keys static while letting the values
# resolve at apply time — exactly the fix OpenTofu's own error message for
# this situation recommends.
resource "aws_iam_role_policy_attachment" "additional" {
  for_each   = { for idx, arn in var.additional_iam_policy_arns : tostring(idx) => arn }
  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# Attach IAM role to instance profile
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.this.name

  tags = var.tags
}
