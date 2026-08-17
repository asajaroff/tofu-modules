resource "aws_s3_bucket" "site_bucket" {
  bucket = var.s3_bucket_name

  tags = merge(
    {
      "Name" = "Static site for ${var.s3_bucket_name}"
    },
  var.extra_tags)
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.site_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.site_bucket.id
  versioning_configuration {
    status = "Enabled"
  }

  lifecycle {
    enabled = var.s3_bucket_versioning
  }
}

resource "aws_s3_bucket_acl" "site_bucket_acl" {
  bucket     = aws_s3_bucket.site_bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.this]
}

resource "aws_s3_bucket_policy" "site_bucket_policy" {
  bucket     = aws_s3_bucket.site_bucket.id
  policy     = data.aws_iam_policy_document.cloudfront_oac_access.json
  depends_on = [aws_s3_bucket_acl.site_bucket_acl]
}


data "aws_iam_policy_document" "cloudfront_oac_access" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      aws_s3_bucket.site_bucket.arn,
      "${aws_s3_bucket.site_bucket.arn}${var.s3_origin_path}",
      "${aws_s3_bucket.site_bucket.arn}${var.s3_origin_path}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.static_site.arn]
    }
  }
}
