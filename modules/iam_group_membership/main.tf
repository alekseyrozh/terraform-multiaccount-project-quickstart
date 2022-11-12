resource "aws_iam_group_membership" "this" {
  name = "${var.group_name}-group-membership"

  users = [for username, userdata in var.all_users : username if contains(userdata.groups, var.group_name)]
  group = var.group_name
}
