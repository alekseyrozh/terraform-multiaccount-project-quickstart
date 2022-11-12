# This is a place to fine grain the permissions for a app role that is assumed by app repo

# Allow assuming corresponding roles in member AWS accounts
resource "aws_iam_role_policy_attachment" "allow_assuming_app_repo_roles" {
  role       = module.github_oidc_app_repo_role.name
  policy_arn = aws_iam_policy.allow_assuming_app_repo_roles.arn
}
resource "aws_iam_policy" "allow_assuming_app_repo_roles" {
  name   = "allow-${var.app_repo}-repo-assuming-app-repo-roles-in-member-accounts"
  policy = data.aws_iam_policy_document.allow_assuming_app_repo_roles.json
}
data "aws_iam_policy_document" "allow_assuming_app_repo_roles" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect    = "Allow"
    resources = var.roles_app_repo_can_assume
  }
}
