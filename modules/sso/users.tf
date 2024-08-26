locals {
  users = {
    "some_user_1" : {
      user_name = "some_user_1"
      email     = "some_user_1@myproject.com"

      given_name   = "Some"
      family_name  = "User"
      display_name = "Some User"
    },
    "some_user_2" : {
      user_name = "some_user_2"
      email     = "some_user_2@myproject.com"

      given_name   = "Some"
      family_name  = "User 2"
      display_name = "Some User 2"
    },
  }

  developers  = [local.users.some_user_1, local.users.some_user_2]
  prod_admins = [local.users.some_user_1]
}
