# first step needs to be done manually, in aws management account go to "IAM Identity Center" and click "enable". Without this step this data block will fail
data "aws_ssoadmin_instances" "this" {}

locals {
  identity_store_id  = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  identity_store_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

resource "aws_identitystore_user" "all_users" {
  identity_store_id = local.identity_store_id
  for_each = local.users

  display_name = each.value.display_name
  user_name    = each.value.user_name

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value = each.value.email
  }
}

# developers
resource "aws_identitystore_group" "developers" {
  display_name      = "developers"
  identity_store_id = local.identity_store_id
}
# resource "aws_identitystore_group_membership" "developers_memebership" {
#   for_each = aws_identitystore_user.all_users

#   identity_store_id = local.identity_store_id
#   group_id          = aws_identitystore_group.developers.group_id
#   member_id         = each.value.user_id
# }
resource "aws_identitystore_group_membership" "developers_memebership" {
  for_each = { for user in aws_identitystore_user.all_users: user.user_name => user if contains([for u in local.developers: u.user_name], user.user_name)}

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.developers.group_id
  member_id         = each.value.user_id
}

# prod admins
resource "aws_identitystore_group" "prod_admins" {
  display_name      = "prod-admins"
  identity_store_id = local.identity_store_id
}
resource "aws_identitystore_group_membership" "prod_admins_memebership" {
  for_each = { for user in aws_identitystore_user.all_users: user.user_name => user if contains([for u in local.prod_admins: u.user_name], user.user_name)}

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.prod_admins.group_id
  member_id         = each.value.user_id
}

# permission sets
resource "aws_ssoadmin_permission_set" "admin" {
  instance_arn = local.identity_store_arn
  name         = "AdministratorAccess"
}
resource "aws_ssoadmin_managed_policy_attachment" "admin_access" {
  instance_arn       = local.identity_store_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
}

resource "aws_ssoadmin_permission_set" "readonly" {
  instance_arn = local.identity_store_arn
  name         = "ReadOnlyAccess"
}
resource "aws_ssoadmin_managed_policy_attachment" "readonly_access" {
  instance_arn       = local.identity_store_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn
}

# account access
resource "aws_ssoadmin_account_assignment" "readonly_permissions_for_all_accounts" {
  for_each = toset(concat([var.management_account_id, var.prod_account_id], var.other_account_ids))

  instance_arn       = local.identity_store_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn

  principal_id   = aws_identitystore_group.developers.group_id
  principal_type = "GROUP"

  target_id   = each.key
  target_type = "AWS_ACCOUNT"
}
resource "aws_ssoadmin_account_assignment" "admin_permissions_for_dev_accounts" {
  for_each = toset(var.other_account_ids)

  instance_arn       = local.identity_store_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = aws_identitystore_group.developers.group_id
  principal_type = "GROUP"

  target_id   = each.key
  target_type = "AWS_ACCOUNT"
}
resource "aws_ssoadmin_account_assignment" "admin_permissions_for_prod_accounts" {
  for_each = toset([var.management_account_id, var.prod_account_id])

  instance_arn       = local.identity_store_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = aws_identitystore_group.prod_admins.group_id
  principal_type = "GROUP"

  target_id   = each.key
  target_type = "AWS_ACCOUNT"
}
