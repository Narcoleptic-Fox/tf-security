/**
 * # GuardDuty Module
 *
 * Provides AWS GuardDuty threat detection:
 * - GuardDuty detector with all protection features
 * - S3 protection
 * - SNS notifications for findings
 */

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# -----------------------------------------------------------------------------
# GuardDuty Detector
# -----------------------------------------------------------------------------

resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency

  datasources {
    s3_logs {
      enable = var.enable_s3_protection
    }

    kubernetes {
      audit_logs {
        enable = var.enable_kubernetes_protection
      }
    }

    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.enable_malware_protection
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-guardduty"
  })
}

# -----------------------------------------------------------------------------
# GuardDuty Feature Configuration (newer features)
# -----------------------------------------------------------------------------

resource "aws_guardduty_detector_feature" "runtime_monitoring" {
  count = var.enable_runtime_monitoring ? 1 : 0

  detector_id = aws_guardduty_detector.main.id
  name        = "RUNTIME_MONITORING"
  status      = "ENABLED"

  dynamic "additional_configuration" {
    for_each = var.enable_eks_runtime_monitoring ? [1] : []
    content {
      name   = "EKS_ADDON_MANAGEMENT"
      status = "ENABLED"
    }
  }

  dynamic "additional_configuration" {
    for_each = var.enable_ecs_runtime_monitoring ? [1] : []
    content {
      name   = "ECS_FARGATE_AGENT_MANAGEMENT"
      status = "ENABLED"
    }
  }
}

resource "aws_guardduty_detector_feature" "lambda_network_logs" {
  count = var.enable_lambda_protection ? 1 : 0

  detector_id = aws_guardduty_detector.main.id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "rds_login_events" {
  count = var.enable_rds_protection ? 1 : 0

  detector_id = aws_guardduty_detector.main.id
  name        = "RDS_LOGIN_EVENTS"
  status      = "ENABLED"
}

# -----------------------------------------------------------------------------
# SNS Topic for Findings
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "findings" {
  count = var.create_sns_topic ? 1 : 0

  name              = "${var.name_prefix}-guardduty-findings"
  kms_master_key_id = var.sns_kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-guardduty-findings"
  })
}

resource "aws_sns_topic_policy" "findings" {
  count = var.create_sns_topic ? 1 : 0

  arn = aws_sns_topic.findings[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.findings[0].arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:events:${local.region}:${local.account_id}:rule/${var.name_prefix}-guardduty-*"
          }
        }
      }
    ]
  })
}

# Email subscriptions
resource "aws_sns_topic_subscription" "email" {
  for_each = var.create_sns_topic ? toset(var.notification_email_addresses) : []

  topic_arn = aws_sns_topic.findings[0].arn
  protocol  = "email"
  endpoint  = each.value
}

# -----------------------------------------------------------------------------
# EventBridge Rules for Findings
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "findings" {
  count = var.enable_eventbridge_notifications ? 1 : 0

  name        = "${var.name_prefix}-guardduty-findings"
  description = "Capture GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = var.min_severity_for_notification != null ? [
        for s in range(var.min_severity_for_notification, 9) : s
      ] : null
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "sns" {
  count = var.enable_eventbridge_notifications && var.create_sns_topic ? 1 : 0

  rule      = aws_cloudwatch_event_rule.findings[0].name
  target_id = "guardduty-to-sns"
  arn       = aws_sns_topic.findings[0].arn

  input_transformer {
    input_paths = {
      severity    = "$.detail.severity"
      type        = "$.detail.type"
      title       = "$.detail.title"
      description = "$.detail.description"
      accountId   = "$.detail.accountId"
      region      = "$.detail.region"
      time        = "$.detail.service.eventLastSeen"
    }

    input_template = <<-EOF
      "GuardDuty Finding Alert"
      
      Severity: <severity>
      Type: <type>
      Title: <title>
      
      Description: <description>
      
      Account: <accountId>
      Region: <region>
      Time: <time>
      
      Please review this finding in the AWS GuardDuty console.
    EOF
  }
}

resource "aws_cloudwatch_event_target" "lambda" {
  count = var.enable_eventbridge_notifications && var.lambda_function_arn != null ? 1 : 0

  rule      = aws_cloudwatch_event_rule.findings[0].name
  target_id = "guardduty-to-lambda"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "guardduty" {
  count = var.enable_eventbridge_notifications && var.lambda_function_arn != null ? 1 : 0

  statement_id  = "AllowGuardDutyEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.findings[0].arn
}

# High severity findings (separate rule for immediate attention)
resource "aws_cloudwatch_event_rule" "high_severity" {
  count = var.enable_eventbridge_notifications && var.enable_high_severity_alert ? 1 : 0

  name        = "${var.name_prefix}-guardduty-high-severity"
  description = "Capture high severity GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [7, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 8, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "high_severity_sns" {
  count = var.enable_eventbridge_notifications && var.enable_high_severity_alert && var.create_sns_topic ? 1 : 0

  rule      = aws_cloudwatch_event_rule.high_severity[0].name
  target_id = "guardduty-high-severity-sns"
  arn       = aws_sns_topic.findings[0].arn

  input_transformer {
    input_paths = {
      severity    = "$.detail.severity"
      type        = "$.detail.type"
      title       = "$.detail.title"
      description = "$.detail.description"
      accountId   = "$.detail.accountId"
      region      = "$.detail.region"
    }

    input_template = <<-EOF
      "🚨 HIGH SEVERITY GuardDuty Finding 🚨"
      
      Severity: <severity>
      Type: <type>
      Title: <title>
      
      Description: <description>
      
      Account: <accountId>
      Region: <region>
      
      IMMEDIATE ACTION REQUIRED - Please investigate this finding immediately.
    EOF
  }
}

# -----------------------------------------------------------------------------
# Findings Filter (suppress known false positives)
# -----------------------------------------------------------------------------

resource "aws_guardduty_filter" "suppression" {
  for_each = var.suppression_filters

  name        = each.key
  action      = "ARCHIVE"
  detector_id = aws_guardduty_detector.main.id
  rank        = each.value.rank

  finding_criteria {
    dynamic "criterion" {
      for_each = each.value.criteria
      content {
        field                 = criterion.value.field
        equals                = lookup(criterion.value, "equals", null)
        not_equals            = lookup(criterion.value, "not_equals", null)
        greater_than          = lookup(criterion.value, "greater_than", null)
        greater_than_or_equal = lookup(criterion.value, "greater_than_or_equal", null)
        less_than             = lookup(criterion.value, "less_than", null)
        less_than_or_equal    = lookup(criterion.value, "less_than_or_equal", null)
      }
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Trusted IP List
# -----------------------------------------------------------------------------

resource "aws_guardduty_ipset" "trusted" {
  count = var.trusted_ip_list_location != null ? 1 : 0

  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = var.trusted_ip_list_format
  location    = var.trusted_ip_list_location
  name        = "${var.name_prefix}-trusted-ips"

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Threat Intel Set
# -----------------------------------------------------------------------------

resource "aws_guardduty_threatintelset" "custom" {
  count = var.threat_intel_set_location != null ? 1 : 0

  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = var.threat_intel_set_format
  location    = var.threat_intel_set_location
  name        = "${var.name_prefix}-threat-intel"

  tags = var.tags
}
