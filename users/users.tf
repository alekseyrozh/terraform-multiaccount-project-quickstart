locals {
  users = {
    "<YOUR_USERNAME>" : {
      email  = "<YOUR_EMAIL>"
      groups = ["developers", "prod-readonly"] # can access dev, ci, staging and prod as readonly
    }
    # "bob" : {
    #   email  = "bob@gmail.com"
    #   groups = ["developers"] # can access dev, ci, staging as readonly
    # },
    # "sam" : {
    #   email  = "sam@gmail.com"
    #   groups = ["developers", "dev-powerusers"] # can access dev, ci, staging as readonly and as poweruser
    # },
    # "john" : {
    #   email  = "john@gmail.com"
    #   groups = ["developers", "prod-readonly"] # can access dev, ci, staging and prod as readonly
    # },
    # "kek" : {
    #   email  = "kek@gmail.com"
    #   groups = ["developers", "prod-readonly", "prod-powerusers"] # can access dev, ci, staging as readonly, and prod as both readonly and poweruser
    # },
    # "lol" : {
    #   email  = "lol@gmail.com"
    #   groups = ["developers", "dev-admins", "prod-admins"] # has full access to all accounts. The only one who can apply terraform locally. As poweruser role is not enough to apply terraform
    # }
  }
}

resource "aws_iam_user" "all" {
  for_each = local.users

  name = each.key
  tags = {
    Email = each.value.email
  }

  force_destroy = true
}
