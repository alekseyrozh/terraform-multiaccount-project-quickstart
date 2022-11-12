variable "name" {
  type = string
}

variable "oidc_github_provider_arn" {
  type = string
}

variable "github_org" {
  description = "GitHub organisation or username which has repos from which the role can be assumed"
  type        = string
}

variable "github_repos" {
  description = "List of GitHub repository names from which the role can be assumed"
  type        = list(string)
}
