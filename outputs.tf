output "management_account" {
  value = {
    app_repo_role_arn       = module.management_account.app_repo_role_arn
    terraform_repo_role_arn = module.management_account.terraform_repo_role_arn

    id = module.management_account.id
  }
}

output "dev_account" {
  value = {
    id = module.dev_account.id
  }
}

output "prod_account" {
  value = {
    id = module.prod_account.id
  }
}
