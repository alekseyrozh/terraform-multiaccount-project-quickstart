resource "aws_iam_group" "dev_admins" {
  name = "dev-admins"
}

module "dev_admins_group_membership" {
  source = "../modules/iam_group_membership"

  all_users  = local.users
  group_name = aws_iam_group.dev_admins.name
  depends_on = [aws_iam_user.all]
}

# policy 

# allow assuming admin role in dev accounts
resource "aws_iam_group_policy_attachment" "allow_assuming_dev_admins_roles" {
  group      = aws_iam_group.dev_admins.name
  policy_arn = aws_iam_policy.allow_assuming_dev_admin_roles.arn
}
resource "aws_iam_policy" "allow_assuming_dev_admin_roles" {
  name   = "allow-assuming-dev-admin-roles"
  policy = data.aws_iam_policy_document.allow_assuming_dev_admin_roles.json
}
data "aws_iam_policy_document" "allow_assuming_dev_admin_roles" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect    = "Allow"
    resources = var.dev_accounts_admin_roles
  }
}
