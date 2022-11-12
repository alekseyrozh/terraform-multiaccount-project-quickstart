output "management_account" {
  value = {
    app_repo_role_arn       = module.management_account.app_repo_role_arn
    terraform_repo_role_arn = module.management_account.terraform_repo_role_arn

    id = module.management_account.id
  }
}

output "dev_account" {
  value = {
    id                 = module.dev_account.id
    readonly_role_arn  = module.dev_account.readonly_role_arn
    poweruser_role_arn = module.dev_account.poweruser_role_arn
  }
}

output "ci_account" {
  value = {
    id                 = module.ci_account.id
    readonly_role_arn  = module.ci_account.readonly_role_arn
    poweruser_role_arn = module.ci_account.poweruser_role_arn
  }
}

output "staging_account" {
  value = {
    id                 = module.staging_account.id
    readonly_role_arn  = module.staging_account.readonly_role_arn
    poweruser_role_arn = module.staging_account.poweruser_role_arn
  }
}

output "prod_account" {
  value = {
    id                 = module.prod_account.id
    readonly_role_arn  = module.prod_account.readonly_role_arn
    poweruser_role_arn = module.prod_account.poweruser_role_arn
  }
}
