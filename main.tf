resource "random_uuid" "zesty_external_id" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  region          = var.region != "" ? var.region : data.aws_region.current.region
  cur_bucket_name = "${var.cur_s3_bucket_prefix}-${data.aws_caller_identity.current.account_id}"

  products = [
    {
      name   = "CM"
      active = false
    }
  ]

  readonly_policy_statements = [
    {
      Sid    = "EC2Access"
      Effect = "Allow"
      Action = [
        "ec2:List*",
        "ec2:Describe*",
        "elasticloadbalancing:Describe*",
        "autoscaling:Describe*"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "OrganizationsAccess"
      Effect = "Allow"
      Action = [
        "organizations:List*",
        "organizations:Describe*"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "ServiceQuotasAccess"
      Effect = "Allow"
      Action = [
        "servicequotas:ListServiceQuotas",
        "servicequotas:GetServiceQuota",
        "servicequotas:GetRequestedServiceQuotaChange"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "MetricsAccess"
      Effect = "Allow"
      Action = [
        "cloudwatch:List*",
        "cloudwatch:Describe*",
        "cloudwatch:GetMetricStatistics"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "SavingsPlansAccess"
      Effect = "Allow"
      Action = [
        "savingsplans:List*",
        "savingsplans:Describe*"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "CostExplorerAccess"
      Effect = "Allow"
      Action = [
        "ce:List*",
        "ce:Describe*",
        "ce:Get*"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "EKSAccess"
      Effect = "Allow"
      Action = [
        "eks:List*",
        "eks:Describe*"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "CostAndUsageReportAccess"
      Effect = "Allow"
      Action = [
        "cur:DescribeReportDefinitions"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "BCMDataExportsAccess"
      Effect = "Allow"
      Action = [
        "bcm-data-exports:ListExports",
        "bcm-data-exports:GetExport"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "CURBucketAccess"
      Effect = "Allow"
      Action = [
        "s3:Get*",
        "s3:List*"
      ]
      Resource = [
        aws_s3_bucket.zesty_cur_bucket.arn,
        "${aws_s3_bucket.zesty_cur_bucket.arn}/*"
      ]
    }
  ]
}

resource "aws_iam_role" "zesty_iam_role" {
  name                 = var.role_name
  max_session_duration = var.max_session_duration
  tags                 = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          AWS = var.trusted_principal
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = random_uuid.zesty_external_id.result
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "zesty_policy" {
  name = var.policy_name
  role = aws_iam_role.zesty_iam_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.readonly_policy_statements
  })
}

resource "aws_s3_bucket" "zesty_cur_bucket" {
  bucket        = local.cur_bucket_name
  force_destroy = var.force_destroy_cur_bucket
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "cur_bucket" {
  bucket = aws_s3_bucket.zesty_cur_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cur_bucket_policy" {
  bucket = aws_s3_bucket.zesty_cur_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCURv1Write"
        Effect = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.zesty_cur_bucket.arn,
          "${aws_s3_bucket.zesty_cur_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_cur_report_definition" "zesty_cur" {
  report_name = var.cur_report_name
  time_unit   = "HOURLY"
  format      = "Parquet"
  compression = "Parquet"

  s3_bucket = aws_s3_bucket.zesty_cur_bucket.bucket
  s3_region = local.region
  s3_prefix = var.cur_s3_prefix

  additional_schema_elements = [
    "RESOURCES",
    "SPLIT_COST_ALLOCATION_DATA"
  ]

  report_versioning = "OVERWRITE_REPORT"

  depends_on = [aws_s3_bucket_policy.cur_bucket_policy]
}

resource "null_resource" "wait_for_iam" {
  provisioner "local-exec" {
    command = "sleep 10"
  }

  depends_on = [aws_iam_role_policy.zesty_policy]
}

resource "zesty_account" "this" {
  account = {
    id             = data.aws_caller_identity.current.account_id
    region         = local.region
    cloud_provider = "AWS"
    role_arn       = aws_iam_role.zesty_iam_role.arn
    external_id    = random_uuid.zesty_external_id.result
    products       = local.products
    cur = {
      s3_bucket       = aws_s3_bucket.zesty_cur_bucket.bucket
      cur_export_name = aws_cur_report_definition.zesty_cur.report_name
      cur_type        = "cur_v1"
    }
  }

  depends_on = [
    aws_cur_report_definition.zesty_cur,
    aws_iam_role_policy.zesty_policy,
    null_resource.wait_for_iam
  ]
}
