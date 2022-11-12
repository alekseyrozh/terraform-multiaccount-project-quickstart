variable "group_name" {
  type = string
}

variable "all_users" {
  type = map(object({
    email  = string
    groups = list(string)
  }))
}
