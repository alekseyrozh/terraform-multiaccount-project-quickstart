resource "aws_iam_group" "prod_readonly" {
  name = "prod-readonly"
}

module "prod_readonly_group_membership" {
  source = "../modules/iam_group_membership"

  all_users  = local.users
  group_name = aws_iam_group.prod_readonly.name
  depends_on = [aws_iam_user.all]
}

# policy

# allow assuming readonly role in prod accounts
resource "aws_iam_group_policy_attachment" "allow_assuming_prod_readonly_roles" {
  group      = aws_iam_group.prod_readonly.name
  policy_arn = aws_iam_policy.allow_assuming_prod_readonly_roles.arn
}
resource "aws_iam_policy" "allow_assuming_prod_readonly_roles" {
  name   = "allow-assuming-prod-readonly-roles"
  policy = data.aws_iam_policy_document.allow_assuming_prod_readonly_roles.json
}
data "aws_iam_policy_document" "allow_assuming_prod_readonly_roles" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect    = "Allow"
    resources = var.prod_accounts_readonly_roles
  }
}
