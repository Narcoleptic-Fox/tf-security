/**
 * # VPC Security Module
 *
 * Provides network security controls for VPCs including:
 * - Security group templates for web/app/db tiers
 * - Network ACLs for public/private subnets
 * - VPC Flow Logs configuration
 */

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# -----------------------------------------------------------------------------
# Security Groups - Web Tier (Public-facing)
# -----------------------------------------------------------------------------

resource "aws_security_group" "web" {
  count = var.create_web_security_group ? 1 : 0

  name_prefix = "${var.name_prefix}-web-"
  vpc_id      = var.vpc_id
  description = "Security group for web tier (ALB/NLB)"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-web-sg"
    Tier = "web"
  })
}

resource "aws_security_group_rule" "web_ingress_https" {
  count = var.create_web_security_group ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.web_ingress_cidr_blocks
  ipv6_cidr_blocks  = var.web_ingress_ipv6_cidr_blocks
  security_group_id = aws_security_group.web[0].id
  description       = "HTTPS from allowed sources"
}

resource "aws_security_group_rule" "web_ingress_http" {
  count = var.create_web_security_group && var.allow_http ? 1 : 0

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.web_ingress_cidr_blocks
  ipv6_cidr_blocks  = var.web_ingress_ipv6_cidr_blocks
  security_group_id = aws_security_group.web[0].id
  description       = "HTTP from allowed sources (for redirect)"
}

resource "aws_security_group_rule" "web_egress_app" {
  count = var.create_web_security_group && var.create_app_security_group ? 1 : 0

  type                     = "egress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app[0].id
  security_group_id        = aws_security_group.web[0].id
  description              = "To application tier"
}

# -----------------------------------------------------------------------------
# Security Groups - App Tier (Private)
# -----------------------------------------------------------------------------

resource "aws_security_group" "app" {
  count = var.create_app_security_group ? 1 : 0

  name_prefix = "${var.name_prefix}-app-"
  vpc_id      = var.vpc_id
  description = "Security group for application tier"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-sg"
    Tier = "app"
  })
}

resource "aws_security_group_rule" "app_ingress_web" {
  count = var.create_app_security_group && var.create_web_security_group ? 1 : 0

  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web[0].id
  security_group_id        = aws_security_group.app[0].id
  description              = "From web tier"
}

resource "aws_security_group_rule" "app_egress_db" {
  count = var.create_app_security_group && var.create_db_security_group ? 1 : 0

  type                     = "egress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db[0].id
  security_group_id        = aws_security_group.app[0].id
  description              = "To database tier"
}

resource "aws_security_group_rule" "app_egress_https" {
  count = var.create_app_security_group ? 1 : 0

  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app[0].id
  description       = "HTTPS outbound (AWS APIs, external services)"
}

# -----------------------------------------------------------------------------
# Security Groups - Database Tier (Isolated)
# -----------------------------------------------------------------------------

resource "aws_security_group" "db" {
  count = var.create_db_security_group ? 1 : 0

  name_prefix = "${var.name_prefix}-db-"
  vpc_id      = var.vpc_id
  description = "Security group for database tier"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-sg"
    Tier = "database"
  })
}

resource "aws_security_group_rule" "db_ingress_app" {
  count = var.create_db_security_group && var.create_app_security_group ? 1 : 0

  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app[0].id
  security_group_id        = aws_security_group.db[0].id
  description              = "From application tier"
}

# No egress for DB tier - databases shouldn't initiate connections

# -----------------------------------------------------------------------------
# Network ACLs - Public Subnet
# -----------------------------------------------------------------------------

resource "aws_network_acl" "public" {
  count = var.create_public_nacl ? 1 : 0

  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-nacl"
    Tier = "public"
  })
}

# Inbound rules for public NACL
resource "aws_network_acl_rule" "public_inbound_https" {
  count = var.create_public_nacl ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_inbound_http" {
  count = var.create_public_nacl && var.allow_http ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_inbound_ephemeral" {
  count = var.create_public_nacl ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Outbound rules for public NACL
resource "aws_network_acl_rule" "public_outbound_https" {
  count = var.create_public_nacl ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_outbound_http" {
  count = var.create_public_nacl ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_outbound_ephemeral" {
  count = var.create_public_nacl ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow internal VPC traffic
resource "aws_network_acl_rule" "public_inbound_vpc" {
  count = var.create_public_nacl ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 300
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "public_outbound_vpc" {
  count = var.create_public_nacl ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 300
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

# -----------------------------------------------------------------------------
# Network ACLs - Private Subnet
# -----------------------------------------------------------------------------

resource "aws_network_acl" "private" {
  count = var.create_private_nacl ? 1 : 0

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-nacl"
    Tier = "private"
  })
}

# Allow all VPC internal traffic
resource "aws_network_acl_rule" "private_inbound_vpc" {
  count = var.create_private_nacl ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "private_outbound_vpc" {
  count = var.create_private_nacl ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

# Ephemeral ports for NAT Gateway responses
resource "aws_network_acl_rule" "private_inbound_ephemeral" {
  count = var.create_private_nacl ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Outbound HTTPS (via NAT)
resource "aws_network_acl_rule" "private_outbound_https" {
  count = var.create_private_nacl ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# -----------------------------------------------------------------------------
# VPC Flow Logs
# -----------------------------------------------------------------------------

resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = var.vpc_id
  traffic_type             = var.flow_log_traffic_type
  iam_role_arn             = var.flow_log_destination == "cloud-watch-logs" ? aws_iam_role.flow_logs[0].arn : null
  log_destination_type     = var.flow_log_destination
  log_destination          = var.flow_log_destination == "cloud-watch-logs" ? aws_cloudwatch_log_group.flow_logs[0].arn : var.flow_log_s3_bucket_arn
  max_aggregation_interval = var.flow_log_aggregation_interval

  dynamic "destination_options" {
    for_each = var.flow_log_destination == "s3" ? [1] : []
    content {
      file_format        = var.flow_log_file_format
      per_hour_partition = var.flow_log_per_hour_partition
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-flow-logs"
  })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination == "cloud-watch-logs" ? 1 : 0

  name              = "/aws/vpc/flow-logs/${var.name_prefix}"
  retention_in_days = var.flow_log_retention_days
  kms_key_id        = var.flow_log_kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-flow-logs"
  })
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination == "cloud-watch-logs" ? 1 : 0

  name = "${var.name_prefix}-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = local.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:aws:ec2:${local.region}:${local.account_id}:vpc-flow-log/*"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs && var.flow_log_destination == "cloud-watch-logs" ? 1 : 0

  name = "cloudwatch-logs"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
    }]
  })
}
