variable "account_name" {
  type = string
}

variable "account_root_email" {
  type = string
}

variable "organizational_unit_id" {
  type = string
}

variable "aws_region" {
  type = string
}


variable "role_name_to_assume" {
  type        = string
  description = "The name of the role that terraform will assume when making changes to this account"
}


# management account roles

variable "management_account_app_repo_role_arn" {
  type = string
}
variable "app_repo_role_name" {
  type = string
}

variable "management_account_terraform_repo_role_arn" {
  type = string
}
variable "terraform_repo_role_name" {
  type = string
}


variable "management_account_id" {
  type = string
}
