output "id" {
  value = aws_organizations_account.this.id
}

output "app_repo_role_arn" {
  value = module.app_repo_role.arn
}

output "terraform_repo_role_arn" {
  value = module.terraform_repo_role.arn
}
