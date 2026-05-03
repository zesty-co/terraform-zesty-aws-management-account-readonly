variable "region" {
  description = "AWS region used for the CUR bucket and Zesty account metadata. Defaults to the configured AWS provider region."
  type        = string
  default     = ""
}

variable "role_name" {
  description = "IAM role name to create in the AWS management account."
  type        = string
  default     = "ZestyIamRole"
}

variable "policy_name" {
  description = "Inline IAM policy name attached to the Zesty IAM role."
  type        = string
  default     = "ZestyPolicy"
}

variable "max_session_duration" {
  description = "Maximum session duration, in seconds, for the Zesty IAM role."
  type        = number
  default     = 43200
}

variable "trusted_principal" {
  description = "Zesty AWS principal allowed to assume the IAM role."
  type        = string
  default     = "arn:aws:iam::672188301118:root"
}

variable "cur_s3_bucket_prefix" {
  description = "Prefix used to build the globally unique CUR bucket name."
  type        = string
  default     = "zesty-cur-bucket"
}

variable "cur_report_name" {
  description = "AWS CUR 1.0 report name."
  type        = string
  default     = "ZestyCurReport"
}

variable "cur_s3_prefix" {
  description = "S3 prefix for CUR delivery."
  type        = string
  default     = "cur"
}

variable "force_destroy_cur_bucket" {
  description = "Whether Terraform may delete non-empty CUR buckets during destroy."
  type        = bool
  default     = false
}

variable "iam_propagation_delay" {
  description = "Duration to wait after IAM role policy changes before calling Zesty validation."
  type        = string
  default     = "20s"
}

variable "tags" {
  description = "Tags applied to created AWS resources that support tagging."
  type        = map(string)
  default     = {}
}
