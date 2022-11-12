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

module "readonly_role" {
  source = "../../modules/cross_account_role"

  name       = "readonly-role"
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  principals = [var.management_account_id]
}

module "poweruser_role" {
  source = "../../modules/cross_account_role"

  name       = "poweruser-role"
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  principals = [var.management_account_id]
}
