/**
 * # Encryption Module
 *
 * Provides KMS key management and encryption configuration:
 * - Customer-managed KMS key with rotation
 * - Key policies for service access
 * - S3 bucket encryption defaults
 */

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # Build service principals list
  service_principals = distinct(concat(
    var.enable_cloudwatch_logs ? ["logs.${local.region}.amazonaws.com"] : [],
    var.enable_s3 ? ["s3.amazonaws.com"] : [],
    var.enable_sns ? ["sns.amazonaws.com"] : [],
    var.enable_sqs ? ["sqs.amazonaws.com"] : [],
    var.enable_lambda ? ["lambda.amazonaws.com"] : [],
    var.enable_secrets_manager ? ["secretsmanager.amazonaws.com"] : [],
    var.enable_ssm ? ["ssm.amazonaws.com"] : [],
    var.enable_rds ? ["rds.amazonaws.com"] : [],
    var.enable_ebs ? ["ec2.amazonaws.com"] : [],
    var.additional_service_principals
  ))

  # Build IAM principals list
  key_admin_arns = length(var.key_admin_arns) > 0 ? var.key_admin_arns : [
    "arn:aws:iam::${local.account_id}:root"
  ]
}

# -----------------------------------------------------------------------------
# KMS Key
# -----------------------------------------------------------------------------

resource "aws_kms_key" "main" {
  description             = var.key_description != null ? var.key_description : "KMS key for ${var.name_prefix}"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = var.multi_region
  is_enabled              = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Root account and key administrators
      [
        {
          Sid    = "EnableRootAccountFullAccess"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${local.account_id}:root"
          }
          Action   = "kms:*"
          Resource = "*"
        }
      ],
      # Key administrators (if different from root)
      length(var.key_admin_arns) > 0 ? tolist([
        {
          Sid    = "AllowKeyAdministration"
          Effect = "Allow"
          Principal = {
            AWS = var.key_admin_arns
          }
          Action = [
            "kms:Create*",
            "kms:Describe*",
            "kms:Enable*",
            "kms:List*",
            "kms:Put*",
            "kms:Update*",
            "kms:Revoke*",
            "kms:Disable*",
            "kms:Get*",
            "kms:Delete*",
            "kms:TagResource",
            "kms:UntagResource",
            "kms:ScheduleKeyDeletion",
            "kms:CancelKeyDeletion"
          ]
          Resource = "*"
        }
      ]) : tolist([]),
      # Key users
      length(var.key_user_arns) > 0 ? tolist([
        {
          Sid    = "AllowKeyUsage"
          Effect = "Allow"
          Principal = {
            AWS = var.key_user_arns
          }
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ]
          Resource = "*"
        },
        {
          Sid    = "AllowKeyGrants"
          Effect = "Allow"
          Principal = {
            AWS = var.key_user_arns
          }
          Action = [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
          ]
          Resource = "*"
          Condition = {
            Bool = {
              "kms:GrantIsForAWSResource" = "true"
            }
          }
        }
      ]) : tolist([]),
      # AWS Service principals
      length(local.service_principals) > 0 ? tolist([
        {
          Sid    = "AllowServiceUsage"
          Effect = "Allow"
          Principal = {
            Service = local.service_principals
          }
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "kms:CallerAccount" = local.account_id
            }
          }
        }
      ]) : tolist([]),
      # Cross-account access
      length(var.cross_account_arns) > 0 ? tolist([
        {
          Sid    = "AllowCrossAccountUsage"
          Effect = "Allow"
          Principal = {
            AWS = var.cross_account_arns
          }
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ]
          Resource = "*"
        }
      ]) : tolist([])
    )
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-key"
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${replace(var.name_prefix, "-", "/")}${var.alias_suffix != "" ? "/${var.alias_suffix}" : ""}"
  target_key_id = aws_kms_key.main.key_id
}

# Additional aliases if specified
resource "aws_kms_alias" "additional" {
  for_each = toset(var.additional_aliases)

  name          = "alias/${each.value}"
  target_key_id = aws_kms_key.main.key_id
}

# -----------------------------------------------------------------------------
# S3 Bucket with Encryption Defaults
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "secure" {
  count = var.create_secure_bucket ? 1 : 0

  bucket = var.bucket_name != null ? var.bucket_name : "${local.account_id}-${var.name_prefix}-secure"

  tags = merge(var.tags, {
    Name = var.bucket_name != null ? var.bucket_name : "${var.name_prefix}-secure"
  })
}

resource "aws_s3_bucket_public_access_block" "secure" {
  count = var.create_secure_bucket ? 1 : 0

  bucket = aws_s3_bucket.secure[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure" {
  count = var.create_secure_bucket ? 1 : 0

  bucket = aws_s3_bucket.secure[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main.arn
    }
    bucket_key_enabled = var.enable_bucket_key
  }
}

resource "aws_s3_bucket_versioning" "secure" {
  count = var.create_secure_bucket ? 1 : 0

  bucket = aws_s3_bucket.secure[0].id

  versioning_configuration {
    status = var.enable_bucket_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_logging" "secure" {
  count = var.create_secure_bucket && var.access_log_bucket != null ? 1 : 0

  bucket = aws_s3_bucket.secure[0].id

  target_bucket = var.access_log_bucket
  target_prefix = "${var.name_prefix}/"
}

resource "aws_s3_bucket_policy" "secure" {
  count = var.create_secure_bucket ? 1 : 0

  bucket = aws_s3_bucket.secure[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.secure[0].arn,
          "${aws_s3_bucket.secure[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "DenyIncorrectEncryptionHeader"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.secure[0].arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.secure[0].arn}/*"
        Condition = {
          Null = {
            "s3:x-amz-server-side-encryption" = "true"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "secure" {
  count = var.create_secure_bucket && var.enable_lifecycle_rules ? 1 : 0

  bucket = aws_s3_bucket.secure[0].id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    filter {}

    transition {
      days          = var.transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    dynamic "transition" {
      for_each = var.transition_to_glacier_days != null ? [1] : []
      content {
        days          = var.transition_to_glacier_days
        storage_class = "GLACIER"
      }
    }

    noncurrent_version_transition {
      noncurrent_days = var.noncurrent_transition_days
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_expiration_days
    }
  }
}
