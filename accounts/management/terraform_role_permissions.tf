# This is a place to fine grain the permissions for a terraform role that is assumed by terraform repo
#  we need this role to have permissions to assume corresponding roles in management account
#  we also need to give the repo permissions to manage the state (s3 + dynamo + kms)
#  and we might want to make adding changes to management account, so the permissions for that should be defined here


# If you are sick or fine graining permissions, just uncomment the code snippet below and remove everything else

# resource "aws_iam_role_policy_attachment" "allow_readonly_all" {
#   role       = module.github_oidc_terraform_repo_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }


# Allow assuming corresponding roles in member AWS accounts
resource "aws_iam_role_policy_attachment" "allow_assuming_terraform_repo_roles" {
  role       = module.github_oidc_terraform_repo_role.name
  policy_arn = aws_iam_policy.allow_assuming_terraform_repo_roles.arn
}
resource "aws_iam_policy" "allow_assuming_terraform_repo_roles" {
  name   = "allow-${var.terraform_repo}-repo-assuming-terraform-repo-roles-in-member-accounts"
  policy = data.aws_iam_policy_document.allow_assuming_terraform_repo_roles.json
}
data "aws_iam_policy_document" "allow_assuming_terraform_repo_roles" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect    = "Allow"
    resources = var.roles_terraform_repo_can_assume
  }
}


# Allow reading all resources so that terraform can plan
resource "aws_iam_role_policy_attachment" "allow_readonly_all" {
  role       = module.github_oidc_terraform_repo_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Terraform state lives in management account, so we need permissions to change it
# full readonly access is already granted, so some permissions from guide below are ommited
# refer to https://developer.hashicorp.com/terraform/language/settings/backends/s3
resource "aws_iam_role_policy_attachment" "allow_changing_terraform_state" {
  role       = module.github_oidc_terraform_repo_role.name
  policy_arn = aws_iam_policy.allow_changing_terraform_state.arn
}
resource "aws_iam_policy" "allow_changing_terraform_state" {
  name   = "allow-changing-terraform-state"
  policy = data.aws_iam_policy_document.allow_changing_terraform_state.json
}
data "aws_iam_policy_document" "allow_changing_terraform_state" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.terraform_state.bucket_name}/${var.terraform_state.path}"]
  }

  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    effect    = "Allow"
    resources = ["arn:aws:dynamodb:*:*:table/${var.terraform_state.dynamo_table_name}"]
  }
}

# Allow modifying IAM to have control over users and policies
resource "aws_iam_role_policy_attachment" "allow_full_iam_access" {
  role       = module.github_oidc_terraform_repo_role.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

# Allow decrypting the contents of s3 terraform state bucket
resource "aws_iam_role_policy_attachment" "allow_decrypting_s3_state_bucket_with_kms_key" {
  role       = module.github_oidc_terraform_repo_role.name
  policy_arn = aws_iam_policy.allow_decrypting_s3_state_bucket_with_kms_key.arn
}
resource "aws_iam_policy" "allow_decrypting_s3_state_bucket_with_kms_key" {
  name   = "allow-decrypting-s3-state-bucket-with-kms-key"
  policy = data.aws_iam_policy_document.allow_decrypting_s3_state_bucket_with_kms_key.json
}
data "aws_iam_policy_document" "allow_decrypting_s3_state_bucket_with_kms_key" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    effect    = "Allow"
    resources = [var.terraform_state.bucket_kms_key_arn]
  }
}
