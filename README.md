# Zesty AWS Management Account Read-Only Onboarding

This module onboards an AWS management account to Zesty in read-only mode for Commitment Manager evaluation.

Use this when a customer wants to grant Zesty management-account visibility through Terraform before enabling CM automation.

It creates:

- An IAM role trusted by the Zesty AWS account
- Read-only account, Cost Explorer, Organizations, Savings Plans, EKS, and CUR permissions
- An S3 bucket for AWS CUR delivery
- A CUR 1.0 report definition
- A CM product registration with `active = false`
- A `zesty_account` registration using the existing `zesty` Terraform provider

```hcl
provider "zesty" {
  token = var.zesty_api_token
}

module "zesty_management_account" {
  source = "zesty-co/aws-management-account-readonly/zesty"
}
```

## Prerequisites

- Terraform >= 1.5
- AWS credentials for the target AWS Organizations management account
- A Zesty Terraform API token for the `zesty` provider

## Upgrade To Full CM

To move from read-only evaluation to active CM automation, keep the same Terraform module block name and change only the module source to the full management-account module:

```hcl
module "zesty_management_account" {
  source = "zesty-co/aws-management-account-readonly/zesty"
}
```

becomes:

```hcl
module "zesty_management_account" {
  source = "zesty-co/aws-management-account/zesty"
}
```

Keeping the same module block name keeps the Terraform resource addresses stable, so Terraform updates the existing IAM role policy and `zesty_account` registration instead of creating a second role. If the module block name changes too, move the state addresses first.

Do not onboard the same account through the UI/CloudFormation flow after Terraform owns these resources. UI to Terraform interoperability is tracked separately under PLAT-125.

## Existing UI/CloudFormation Accounts

This module creates the CUR bucket name as `${cur_s3_bucket_prefix}-${account_id}`. If the same AWS management account was already onboarded through the UI/CloudFormation flow, that bucket or CUR report can already exist and Terraform will fail during creation.

For PLAT-124, use this module for Terraform-owned onboarding only. UI/CloudFormation import and migration guidance belongs to PLAT-125.

## Destroy Behavior

`terraform destroy` removes AWS resources managed by this module and calls the `zesty_account` delete path. The current backend removes the Terraform onboarding account record, but broader product/platform offboarding is not guaranteed by this module. Confirm the intended offboarding behavior with Zesty before using destroy for production customer offboarding.
