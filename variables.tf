variable "role_name_to_assume_in_member_accounts" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of the role that terraform will assume when making changes to member accounts"
}
