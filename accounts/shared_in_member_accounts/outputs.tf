output "app_repo_role_arn" {
  value = module.app_repo_role.arn
}

output "terraform_repo_role_arn" {
  value = module.terraform_repo_role.arn
}

output "readonly_role_arn" {
  value = module.readonly_role.arn
}

output "poweruser_role_arn" {
  value = module.poweruser_role.arn
}
