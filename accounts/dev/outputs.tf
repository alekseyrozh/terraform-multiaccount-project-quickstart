output "id" {
  value = aws_organizations_account.this.id
}

output "app_repo_role_arn" {
  value = module.shared_in_member_accounts.app_repo_role_arn
}

output "terraform_repo_role_arn" {
  value = module.shared_in_member_accounts.terraform_repo_role_arn
}

output "readonly_role_arn" {
  value = module.shared_in_member_accounts.readonly_role_arn
}

output "poweruser_role_arn" {
  value = module.shared_in_member_accounts.poweruser_role_arn
}
