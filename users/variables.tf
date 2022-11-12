variable "dev_accounts_readonly_roles" {
  type = list(string)
}
variable "dev_accounts_poweruser_roles" {
  type = list(string)
}
variable "dev_accounts_admin_roles" {
  type = list(string)
}

variable "prod_accounts_readonly_roles" {
  type = list(string)
}
variable "prod_accounts_poweruser_roles" {
  type = list(string)
}
variable "prod_accounts_admin_roles" {
  type = list(string)
}

variable "allow_decrypting_s3_state_policy_arn" {
  type = string
}
