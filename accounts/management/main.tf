data "aws_caller_identity" "current" {}

# github repo access

module "oidc_github_provider" {
  source = "../../modules/oidc_github_provider"
}

module "github_oidc_app_repo_role" {
  source                   = "../../modules/github_oidc_role"
  oidc_github_provider_arn = module.oidc_github_provider.arn
  github_org               = var.github_org
  github_repos             = [var.app_repo]

  name = var.app_repo_role_name
}

module "github_oidc_terraform_repo_role" {
  source                   = "../../modules/github_oidc_role"
  oidc_github_provider_arn = module.oidc_github_provider.arn
  github_org               = var.github_org
  github_repos             = [var.terraform_repo]

  name = var.terraform_repo_role_name
}


# organization

resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com"
  ]
  feature_set = "ALL"
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.this.roots[0].id
}
