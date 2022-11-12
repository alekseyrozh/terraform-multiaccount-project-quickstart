resource "aws_organizations_account" "this" {
  provider = aws.management

  name      = var.account_name
  email     = var.account_root_email
  parent_id = var.organizational_unit_id
}

module "shared_in_member_accounts" {
  source = "../shared_in_member_accounts"

  management_account_id                      = var.management_account_id
  app_repo_role_name                         = var.app_repo_role_name
  management_account_app_repo_role_arn       = var.management_account_app_repo_role_arn
  terraform_repo_role_name                   = var.terraform_repo_role_name
  management_account_terraform_repo_role_arn = var.management_account_terraform_repo_role_arn
}
