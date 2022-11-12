resource "aws_iam_group" "developers" {
  name = "developers"
}

module "developers_group_membership" {
  source = "../modules/iam_group_membership"

  all_users  = local.users
  group_name = aws_iam_group.developers.name
  depends_on = [aws_iam_user.all]
}


# policy 

# allow read only access to everything
# in theory this can be removed, as developers don't need to see anything in management account
resource "aws_iam_group_policy_attachment" "developers_read_only_access" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# allow managing your own credentials
# taken from https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_my-sec-creds-self-manage-pass-accesskeys-ssh.html
resource "aws_iam_group_policy_attachment" "allow_managing_your_credentials" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.allow_managing_your_credentials.arn
}
resource "aws_iam_policy" "allow_managing_your_credentials" {
  name   = "allow-managing-your-credentials"
  policy = data.aws_iam_policy_document.allow_managing_your_credentials.json
}
# some of those are commented out as ReadOnlyAccess is already granted
data "aws_iam_policy_document" "allow_managing_your_credentials" {
  # statement {
  #   sid    = "AllowViewAccountInfo"
  #   effect = "Allow"
  #   actions = [
  #     "iam:GetAccountPasswordPolicy",
  #     "iam:GetAccountSummary",
  #   ]
  #   resources = ["*"]
  # }
  statement {
    sid    = "AllowManageOwnPasswords"
    effect = "Allow"
    actions = [
      "iam:ChangePassword",
      # "iam:GetUser",
      # "iam:GetLoginProfile",
      "iam:UpdateLoginProfile"
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"] # $$ is used so that terraform doesn't try to interpolate this string
  }
  statement {
    sid    = "AllowManageOwnAccessKeys"
    effect = "Allow"
    actions = [
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      # "iam:ListAccessKeys",
      "iam:UpdateAccessKey"
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }
  statement {
    sid    = "AllowManageOwnSSHPublicKeys"
    effect = "Allow"
    actions = [
      "iam:DeleteSSHPublicKey",
      # "iam:GetSSHPublicKey",
      # "iam:ListSSHPublicKeys",
      "iam:UpdateSSHPublicKey",
      "iam:UploadSSHPublicKey"
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }
}

# If want to add ability to MFA, refer to
# https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_my-sec-creds-self-manage-mfa-only.html

# allow assuming readonly role in dev accounts
resource "aws_iam_group_policy_attachment" "allow_assuming_dev_readonly_roles" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.allow_assuming_dev_readonly_roles.arn
}
resource "aws_iam_policy" "allow_assuming_dev_readonly_roles" {
  name   = "allow-assuming-dev-readonly-roles"
  policy = data.aws_iam_policy_document.allow_assuming_dev_readonly_roles.json
}
data "aws_iam_policy_document" "allow_assuming_dev_readonly_roles" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect    = "Allow"
    resources = var.dev_accounts_readonly_roles
  }
}

# Allow decrypting the contents of s3 terraform state bucket, so that developers can do terraform plan
resource "aws_iam_group_policy_attachment" "allow_decrypting_s3_state_bucket_with_kms_key" {
  group      = aws_iam_group.developers.name
  policy_arn = var.allow_decrypting_s3_state_policy_arn
}
