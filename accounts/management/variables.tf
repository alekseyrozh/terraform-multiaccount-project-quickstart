variable "github_org" {
  type = string
}
variable "app_repo" {
  type = string
}
variable "terraform_repo" {
  type = string
}

variable "app_repo_role_name" {
  type = string
}
variable "terraform_repo_role_name" {
  type = string
}

variable "roles_app_repo_can_assume" {
  type = list(string)
}
variable "roles_terraform_repo_can_assume" {
  type = list(string)
}

variable "terraform_state" {
  type = object({
    bucket_name        = string
    path               = string
    bucket_kms_key_arn = string

    dynamo_table_name = string
  })
}
