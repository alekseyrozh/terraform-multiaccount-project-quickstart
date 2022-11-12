resource "aws_iam_group" "prod_powerusers" {
  name = "prod-powerusers"
}

module "prod_powerusers_group_membership" {
  source = "../modules/iam_group_membership"

  all_users  = local.users
  group_name = aws_iam_group.prod_powerusers.name
  depends_on = [aws_iam_user.all]
}

# policy 

# allow assuming poweruser role in prod accounts
resource "aws_iam_group_policy_attachment" "allow_assuming_prod_poweruser_roles" {
  group      = aws_iam_group.prod_powerusers.name
  policy_arn = aws_iam_policy.allow_assuming_prod_poweruser_roles.arn
}
resource "aws_iam_policy" "allow_assuming_prod_poweruser_roles" {
  name   = "allow-assuming-prod-poweruser-roles"
  policy = data.aws_iam_policy_document.allow_assuming_prod_poweruser_roles.json
}
data "aws_iam_policy_document" "allow_assuming_prod_poweruser_roles" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect    = "Allow"
    resources = var.prod_accounts_poweruser_roles
  }
}
