# Superseded: Zesty AWS Management Account Read-Only Onboarding

This repository was created during PLAT-124 exploration and has been superseded by the single Zesty AWS management-account module.

Use `zesty-co/aws-management-account/zesty` with `cm_access_mode = "readonly"` instead:

```hcl
provider "zesty" {
  token = var.zesty_api_token
}

module "zesty_management_account" {
  source = "zesty-co/aws-management-account/zesty"

  cm_access_mode = "readonly"
}
```

To enable full CM automation later, keep the same module block and change only:

```hcl
cm_access_mode = "full"
```

The single-module approach avoids duplicate IAM policy maintenance and avoids the Terraform state footgun of changing module sources during read-only to full CM upgrades.

## Original Scope

This repository's original implementation onboarded an AWS management account to Zesty in read-only mode for Commitment Manager evaluation.

It created:

- An IAM role trusted by the Zesty AWS account
- Read-only account, Cost Explorer, Organizations, Savings Plans, EKS, and CUR permissions
- An S3 bucket for AWS CUR delivery
- A CUR 1.0 report definition
- A CM product registration with `active = false`
- A `zesty_account` registration using the existing `zesty` Terraform provider

Do not publish this repository as a Terraform Registry module for PLAT-124.

## Prerequisites

- Terraform >= 1.5
- AWS credentials for the target AWS Organizations management account
- A Zesty Terraform API token for the `zesty` provider

## Existing UI/CloudFormation Accounts

The single module creates the CUR bucket name as `${cur_s3_bucket_prefix}-${account_id}`. If the same AWS management account was already onboarded through the UI/CloudFormation flow, that bucket or CUR report can already exist and Terraform will fail during creation.

For PLAT-124, use Terraform-owned onboarding only. UI/CloudFormation import and migration guidance belongs to PLAT-125.

## Destroy Behavior

`terraform destroy` removes AWS resources managed by the single module and calls the `zesty_account` delete path. The current backend removes the Terraform onboarding account record, but broader product/platform offboarding is not guaranteed by the module. Confirm the intended offboarding behavior with Zesty before using destroy for production customer offboarding.
