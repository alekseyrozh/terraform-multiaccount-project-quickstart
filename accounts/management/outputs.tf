output "organizational_unit_id" {
  value = aws_organizations_organizational_unit.workloads.id
}

output "app_repo_role_arn" {
  value = module.github_oidc_app_repo_role.arn
}
output "terraform_repo_role_arn" {
  value = module.github_oidc_terraform_repo_role.arn
}

output "id" {
  value = data.aws_caller_identity.current.account_id
}

output "allow_decrypting_s3_state_policy_arn" {
  value = aws_iam_policy.allow_decrypting_s3_state_bucket_with_kms_key.arn
}
