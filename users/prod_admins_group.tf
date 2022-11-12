resource "aws_iam_group" "prod_admins" {
  name = "prod-admins"
}

module "prod_admins_group_membership" {
  source = "../modules/iam_group_membership"

  all_users  = local.users
  group_name = aws_iam_group.prod_admins.name
  depends_on = [aws_iam_user.all]
}

# policy 

# allow assuming admin role in prod accounts
resource "aws_iam_group_policy_attachment" "allow_assuming_prod_admin_roles" {
  group      = aws_iam_group.prod_admins.name
  policy_arn = aws_iam_policy.allow_assuming_prod_admin_roles.arn
}
resource "aws_iam_policy" "allow_assuming_prod_admin_roles" {
  name   = "allow-assuming-prod-admin-roles"
  policy = data.aws_iam_policy_document.allow_assuming_prod_admin_roles.json
}
data "aws_iam_policy_document" "allow_assuming_prod_admin_roles" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect    = "Allow"
    resources = var.prod_accounts_admin_roles
  }
}
