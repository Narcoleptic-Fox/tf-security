/**
 * # IAM Baseline Module
 *
 * Provides least-privilege IAM patterns for common AWS services.
 * 
 * Includes:
 * - Lambda execution role with CloudWatch Logs
 * - ECS task role template
 * - EC2 instance profile with SSM
 * - Cross-account assume role pattern
 */

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# -----------------------------------------------------------------------------
# Lambda Execution Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda_execution" {
  count = var.create_lambda_role ? 1 : 0

  name        = "${var.name_prefix}-lambda-execution"
  description = "Lambda execution role with least-privilege permissions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "lambda_logs" {
  count = var.create_lambda_role ? 1 : 0

  name = "cloudwatch-logs"
  role = aws_iam_role.lambda_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudWatchLogs"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = [
        "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${var.name_prefix}*:*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "lambda_xray" {
  count = var.create_lambda_role && var.enable_xray_tracing ? 1 : 0

  name = "xray-tracing"
  role = aws_iam_role.lambda_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowXRayTracing"
      Effect = "Allow"
      Action = [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords",
        "xray:GetSamplingRules",
        "xray:GetSamplingTargets",
        "xray:GetSamplingStatisticSummaries"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count = var.create_lambda_role && var.enable_lambda_vpc_access ? 1 : 0

  role       = aws_iam_role.lambda_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# -----------------------------------------------------------------------------
# ECS Task Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task" {
  count = var.create_ecs_task_role ? 1 : 0

  name        = "${var.name_prefix}-ecs-task"
  description = "ECS task role for application permissions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = local.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:aws:ecs:${local.region}:${local.account_id}:*"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role" "ecs_execution" {
  count = var.create_ecs_task_role ? 1 : 0

  name        = "${var.name_prefix}-ecs-execution"
  description = "ECS task execution role for pulling images and secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  count = var.create_ecs_task_role ? 1 : 0

  role       = aws_iam_role.ecs_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  count = var.create_ecs_task_role && length(var.ecs_secret_arns) > 0 ? 1 : 0

  name = "secrets-access"
  role = aws_iam_role.ecs_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowSecretsAccess"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.ecs_secret_arns
      },
      {
        Sid      = "AllowSSMParameters"
        Effect   = "Allow"
        Action   = ["ssm:GetParameters"]
        Resource = var.ecs_ssm_parameter_arns
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# EC2 Instance Profile with SSM
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ec2_ssm" {
  count = var.create_ec2_ssm_role ? 1 : 0

  name        = "${var.name_prefix}-ec2-ssm"
  description = "EC2 instance role with SSM access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  count = var.create_ec2_ssm_role ? 1 : 0

  role       = aws_iam_role.ec2_ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  count = var.create_ec2_ssm_role && var.enable_ec2_cloudwatch ? 1 : 0

  role       = aws_iam_role.ec2_ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  count = var.create_ec2_ssm_role ? 1 : 0

  name = "${var.name_prefix}-ec2-ssm"
  role = aws_iam_role.ec2_ssm[0].name

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Cross-Account Assume Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "cross_account" {
  count = var.create_cross_account_role ? 1 : 0

  name        = "${var.name_prefix}-cross-account"
  description = "Cross-account role for ${var.cross_account_purpose}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = [
          for account_id in var.trusted_account_ids :
          "arn:aws:iam::${account_id}:root"
        ]
      }
      Action = "sts:AssumeRole"
      Condition = var.require_external_id ? {
        StringEquals = {
          "sts:ExternalId" = var.external_id
        }
      } : null
    }]
  })

  max_session_duration = var.cross_account_max_session_duration

  tags = var.tags
}

resource "aws_iam_role_policy" "cross_account" {
  count = var.create_cross_account_role && var.cross_account_policy_json != null ? 1 : 0

  name   = "cross-account-permissions"
  role   = aws_iam_role.cross_account[0].id
  policy = var.cross_account_policy_json
}
