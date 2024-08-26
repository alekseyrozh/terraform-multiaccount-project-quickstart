resource "aws_organizations_account" "this" {
  provider = aws.management

  name      = var.account_name
  email     = var.account_root_email
  parent_id = var.organizational_unit_id
}

module "app_repo_role" {
  source = "../../modules/cross_account_role"

  name       = var.app_repo_role_name
  principals = [var.management_account_app_repo_role_arn]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

module "terraform_repo_role" {
  source = "../../modules/cross_account_role"

  name       = var.terraform_repo_role_name
  principals = [var.management_account_terraform_repo_role_arn]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
