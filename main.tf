terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  # backend "s3" {
  #   region         = "<YOUR_AWS_REGION>"
  #   bucket         = "terraform-state-for-terraform-state-for-<YOUR_GITHUB_ORG or USERNAME>-<YOUR_GITHUB_TERRAFORM_REPO_NAME>"
  #   key            = "org-shared-state/terraform.tfstate"
  #   dynamodb_table = "terraform-state-lock"
  #   kms_key_id     = "alias/terraform-bucket-key"

  #   encrypt = true
  # }
}


# Those values are not passed as variables because sadly you need to hardcode them in "backend" above
# so let's at least keep them close to one another
# This can be avoided by using Terragrunt, but that's an adventure for another day
locals {
  aws_region                             = "<YOUR_AWS_REGION>"
  terraform_state_bucket_name            = "terraform-state-for-terraform-state-for-<YOUR_GITHUB_ORG or USERNAME>-<YOUR_GITHUB_TERRAFORM_REPO_NAME>" # or anything else unique accross whole AWS
  terraform_state_path                   = "org-shared-state/terraform.tfstate"
  terraform_state_dynamo_lock_table_name = "terraform-state-lock"
  terraform_state_kms_key_alias          = "alias/terraform-bucket-key"

  github_org            = "<YOUR_GITHUB_ORG or USERNAME>"
  github_app_repo       = "<YOUR_GITHUB_APP_REPO_NAME>"
  github_terraform_repo = "<YOUR_GITHUB_TERRAFORM_REPO_NAME>"

  dev_account_name       = "<YOUR_DEV_ACCOUNT_NAME>"       # like myproject-dev
  dev_account_root_email = "<YOUR_DEV_ACCOUNT_ROOT_EMAIL>" # like myproject+dev@gmail.com

  ci_account_name       = "<YOUR_CI_ACCOUNT_NAME>"       # like myproject-ci
  ci_account_root_email = "<YOUR_CI_ACCOUNT_ROOT_EMAIL>" # like myproject+ci@gmail.com

  staging_account_name       = "<YOUR_STAGING_ACCOUNT_NAME>"       # like myproject-staging
  staging_account_root_email = "<YOUR_STAGING_ACCOUNT_ROOT_EMAIL>" # like myproject+staging@gmail.com

  prod_account_name       = "<YOUR_PROD_ACCOUNT_NAME>"       # like myproject-prod
  prod_account_root_email = "<YOUR_PROD_ACCOUNT_ROOT_EMAIL>" # like myproject+prod@gmail.com
}

provider "aws" {
  region = local.aws_region
}

locals {
  app_repo_role_name       = "github-role-for-${local.github_app_repo}-repo"
  terraform_repo_role_name = "github-role-for-${local.github_terraform_repo}-repo"

  # this is purely for providers to assume the right role, when running terraform
  role_name_to_assume_in_member_accounts = coalesce(var.role_name_to_assume_in_member_accounts, local.terraform_repo_role_name)
}

module "terraform_backend" {
  source = "./backend"

  state_bucket_name      = local.terraform_state_bucket_name
  dynamo_lock_table_name = local.terraform_state_dynamo_lock_table_name
  kms_key_alias          = local.terraform_state_kms_key_alias
}

module "management_account" {
  source = "./accounts/management"

  github_org     = local.github_org
  app_repo       = local.github_app_repo
  terraform_repo = local.github_terraform_repo

  app_repo_role_name = local.app_repo_role_name
  roles_app_repo_can_assume = [
    module.dev_account.app_repo_role_arn,
    module.ci_account.app_repo_role_arn,
    module.staging_account.app_repo_role_arn,
    module.prod_account.app_repo_role_arn
  ]

  terraform_repo_role_name = local.terraform_repo_role_name
  roles_terraform_repo_can_assume = [
    module.dev_account.terraform_repo_role_arn,
    module.ci_account.terraform_repo_role_arn,
    module.staging_account.terraform_repo_role_arn,
    module.prod_account.terraform_repo_role_arn
  ]

  terraform_state = {
    bucket_name        = local.terraform_state_bucket_name
    path               = local.terraform_state_path
    bucket_kms_key_arn = module.terraform_backend.kms_terraform_bucket_key_arn

    dynamo_table_name = local.terraform_state_dynamo_lock_table_name
  }
}

module "dev_account" {
  source = "./accounts/dev"

  providers = {
    aws.management = aws
  }
  role_name_to_assume = local.role_name_to_assume_in_member_accounts

  management_account_id = module.management_account.id

  account_name       = local.dev_account_name
  account_root_email = local.dev_account_root_email

  aws_region             = local.aws_region
  organizational_unit_id = module.management_account.organizational_unit_id

  management_account_app_repo_role_arn       = module.management_account.app_repo_role_arn
  management_account_terraform_repo_role_arn = module.management_account.terraform_repo_role_arn
  app_repo_role_name                         = local.app_repo_role_name
  terraform_repo_role_name                   = local.terraform_repo_role_name
}

module "ci_account" {
  source = "./accounts/ci"

  providers = {
    aws.management = aws
  }
  role_name_to_assume = local.role_name_to_assume_in_member_accounts

  management_account_id = module.management_account.id

  account_name       = local.ci_account_name
  account_root_email = local.ci_account_root_email

  aws_region             = local.aws_region
  organizational_unit_id = module.management_account.organizational_unit_id

  management_account_app_repo_role_arn       = module.management_account.app_repo_role_arn
  management_account_terraform_repo_role_arn = module.management_account.terraform_repo_role_arn
  app_repo_role_name                         = local.app_repo_role_name
  terraform_repo_role_name                   = local.terraform_repo_role_name
}

module "staging_account" {
  source = "./accounts/staging"

  providers = {
    aws.management = aws
  }
  role_name_to_assume = local.role_name_to_assume_in_member_accounts

  management_account_id = module.management_account.id

  account_name       = local.staging_account_name
  account_root_email = local.staging_account_root_email

  aws_region             = local.aws_region
  organizational_unit_id = module.management_account.organizational_unit_id

  management_account_app_repo_role_arn       = module.management_account.app_repo_role_arn
  management_account_terraform_repo_role_arn = module.management_account.terraform_repo_role_arn
  app_repo_role_name                         = local.app_repo_role_name
  terraform_repo_role_name                   = local.terraform_repo_role_name
}

module "prod_account" {
  source = "./accounts/prod"

  providers = {
    aws.management = aws
  }
  role_name_to_assume = local.role_name_to_assume_in_member_accounts

  management_account_id = module.management_account.id

  account_name       = local.prod_account_name
  account_root_email = local.prod_account_root_email

  aws_region             = local.aws_region
  organizational_unit_id = module.management_account.organizational_unit_id

  management_account_app_repo_role_arn       = module.management_account.app_repo_role_arn
  management_account_terraform_repo_role_arn = module.management_account.terraform_repo_role_arn
  app_repo_role_name                         = local.app_repo_role_name
  terraform_repo_role_name                   = local.terraform_repo_role_name
}

// users are gonna be created in management account
module "users" {
  source = "./users"
  dev_accounts_readonly_roles = [
    module.dev_account.readonly_role_arn,
    module.ci_account.readonly_role_arn,
    module.staging_account.readonly_role_arn
  ]
  dev_accounts_poweruser_roles = [
    module.dev_account.poweruser_role_arn,
    module.ci_account.poweruser_role_arn,
    module.staging_account.poweruser_role_arn
  ]
  # utilize the admin role created in each member account by default
  dev_accounts_admin_roles = [
    "arn:aws:iam::${module.dev_account.id}:role/OrganizationAccountAccessRole",
    "arn:aws:iam::${module.ci_account.id}:role/OrganizationAccountAccessRole",
    "arn:aws:iam::${module.staging_account.id}:role/OrganizationAccountAccessRole"
  ]

  prod_accounts_readonly_roles = [
    module.prod_account.readonly_role_arn
  ]
  prod_accounts_poweruser_roles = [
    module.prod_account.poweruser_role_arn
  ]
  # utilize the admin role created in each member account by default
  prod_accounts_admin_roles = [
    "arn:aws:iam::${module.prod_account.id}:role/OrganizationAccountAccessRole",
  ]

  allow_decrypting_s3_state_policy_arn = module.management_account.allow_decrypting_s3_state_policy_arn
}
