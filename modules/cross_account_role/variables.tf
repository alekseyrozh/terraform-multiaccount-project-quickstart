variable "principals" {
  type        = list(string)
  description = "Who this role will trust and allow to assume itself. Can be iam user arn, AWS account id for which all users should be trusted"
}

variable "name" {
  type = string
}

variable "policy_arn" {
  type = string
}
