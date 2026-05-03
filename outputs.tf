output "account_id" {
  description = "AWS account ID onboarded to Zesty."
  value       = data.aws_caller_identity.current.account_id
}

output "role_arn" {
  description = "IAM role ARN assumed by Zesty."
  value       = aws_iam_role.zesty_iam_role.arn
}

output "external_id" {
  description = "External ID configured in the IAM role trust policy."
  value       = random_uuid.zesty_external_id.result
  sensitive   = true
}

output "cur_bucket" {
  description = "S3 bucket receiving CUR files."
  value       = aws_s3_bucket.zesty_cur_bucket.bucket
}

output "cur_report_name" {
  description = "AWS CUR report name."
  value       = aws_cur_report_definition.zesty_cur.report_name
}

output "zesty_account_id" {
  description = "Zesty provider account resource ID."
  value       = zesty_account.this.id
}
