/**
 * # Logging Module
 *
 * Provides centralized logging infrastructure:
 * - CloudTrail with S3 destination
 * - CloudWatch Log Groups with retention
 * - Metric filters for security events
 */

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  cloudtrail_log_group_name = "/aws/cloudtrail/${var.name_prefix}"
}

# -----------------------------------------------------------------------------
# CloudTrail S3 Bucket
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "cloudtrail" {
  count = var.create_cloudtrail && var.create_cloudtrail_bucket ? 1 : 0

  bucket = var.cloudtrail_bucket_name != null ? var.cloudtrail_bucket_name : "${local.account_id}-${var.name_prefix}-cloudtrail"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cloudtrail"
  })
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count = var.create_cloudtrail && var.create_cloudtrail_bucket ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  count = var.create_cloudtrail && var.create_cloudtrail_bucket ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null ? true : false
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count = var.create_cloudtrail && var.create_cloudtrail_bucket ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  count = var.create_cloudtrail && var.create_cloudtrail_bucket ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    id     = "cloudtrail-lifecycle"
    status = "Enabled"

    transition {
      days          = var.cloudtrail_transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.cloudtrail_transition_to_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.cloudtrail_expiration_days
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count = var.create_cloudtrail && var.create_cloudtrail_bucket ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail[0].arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:${local.region}:${local.account_id}:trail/${var.name_prefix}-trail"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail[0].arn}/AWSLogs/${local.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "AWS:SourceArn" = "arn:aws:cloudtrail:${local.region}:${local.account_id}:trail/${var.name_prefix}-trail"
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.cloudtrail[0].arn,
          "${aws_s3_bucket.cloudtrail[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudTrail
# -----------------------------------------------------------------------------

resource "aws_cloudtrail" "main" {
  count = var.create_cloudtrail ? 1 : 0

  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = var.create_cloudtrail_bucket ? aws_s3_bucket.cloudtrail[0].id : var.cloudtrail_bucket_name
  s3_key_prefix                 = var.cloudtrail_s3_key_prefix
  include_global_service_events = var.include_global_service_events
  is_multi_region_trail         = var.is_multi_region_trail
  enable_log_file_validation    = var.enable_log_file_validation
  kms_key_id                    = var.kms_key_arn

  cloud_watch_logs_group_arn = var.enable_cloudwatch_logs ? "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*" : null
  cloud_watch_logs_role_arn  = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail_cloudwatch[0].arn : null

  dynamic "event_selector" {
    for_each = var.enable_data_events ? [1] : []
    content {
      read_write_type           = "All"
      include_management_events = true

      dynamic "data_resource" {
        for_each = var.data_event_s3_buckets
        content {
          type   = "AWS::S3::Object"
          values = [data_resource.value]
        }
      }

      dynamic "data_resource" {
        for_each = var.data_event_lambda_functions
        content {
          type   = "AWS::Lambda::Function"
          values = [data_resource.value]
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-trail"
  })

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group for CloudTrail
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cloudtrail" {
  count = var.create_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0

  name              = local.cloudtrail_log_group_name
  retention_in_days = var.cloudtrail_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cloudtrail"
  })
}

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  count = var.create_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0

  name = "${var.name_prefix}-cloudtrail-cw"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  count = var.create_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0

  name = "cloudwatch-logs"
  role = aws_iam_role.cloudtrail_cloudwatch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
    }]
  })
}

# -----------------------------------------------------------------------------
# Application Log Groups
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "application" {
  for_each = var.application_log_groups

  name              = each.value.name
  retention_in_days = lookup(each.value, "retention_days", var.default_log_retention_days)
  kms_key_id        = lookup(each.value, "kms_key_arn", var.kms_key_arn)

  tags = merge(var.tags, {
    Name = each.key
  })
}

# -----------------------------------------------------------------------------
# Security Metric Filters
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_metric_filter" "security_events" {
  for_each = var.create_cloudtrail && var.enable_cloudwatch_logs && var.enable_security_metric_filters ? local.security_metric_filters : {}

  name           = each.key
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name
  pattern        = each.value.pattern

  metric_transformation {
    name          = each.key
    namespace     = var.metric_namespace
    value         = "1"
    default_value = "0"
  }
}

locals {
  security_metric_filters = {
    "UnauthorizedAPICalls" = {
      pattern     = "{ ($.errorCode = \"*UnauthorizedAccess*\") || ($.errorCode = \"AccessDenied*\") }"
      description = "Unauthorized API calls"
    }
    "ConsoleSignInWithoutMFA" = {
      pattern     = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"
      description = "Console sign-in without MFA"
    }
    "RootAccountUsage" = {
      pattern     = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
      description = "Root account usage"
    }
    "IAMPolicyChanges" = {
      pattern     = "{ ($.eventName=DeleteGroupPolicy) || ($.eventName=DeleteRolePolicy) || ($.eventName=DeleteUserPolicy) || ($.eventName=PutGroupPolicy) || ($.eventName=PutRolePolicy) || ($.eventName=PutUserPolicy) || ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=CreatePolicyVersion) || ($.eventName=DeletePolicyVersion) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) || ($.eventName=AttachUserPolicy) || ($.eventName=DetachUserPolicy) || ($.eventName=AttachGroupPolicy) || ($.eventName=DetachGroupPolicy) }"
      description = "IAM policy changes"
    }
    "CloudTrailConfigChanges" = {
      pattern     = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
      description = "CloudTrail configuration changes"
    }
    "ConsoleSignInFailures" = {
      pattern     = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
      description = "Console sign-in failures"
    }
    "DisableOrDeleteCMK" = {
      pattern     = "{ ($.eventSource = kms.amazonaws.com) && (($.eventName=DisableKey) || ($.eventName=ScheduleKeyDeletion)) }"
      description = "KMS key disable or deletion"
    }
    "S3BucketPolicyChanges" = {
      pattern     = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
      description = "S3 bucket policy changes"
    }
    "SecurityGroupChanges" = {
      pattern     = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
      description = "Security group changes"
    }
    "NACLChanges" = {
      pattern     = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
      description = "Network ACL changes"
    }
    "VPCChanges" = {
      pattern     = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
      description = "VPC changes"
    }
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms for Security Events
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "security_events" {
  for_each = var.create_cloudtrail && var.enable_cloudwatch_logs && var.enable_security_alarms ? local.security_metric_filters : {}

  alarm_name          = "${var.name_prefix}-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = each.key
  namespace           = var.metric_namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = each.value.description
  alarm_actions       = var.alarm_sns_topic_arns
  ok_actions          = var.alarm_sns_topic_arns

  treat_missing_data = "notBreaching"

  tags = var.tags
}
