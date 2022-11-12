resource "aws_iam_role" "this" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    # Allow anyone in the management account to assume this role,
    # although not everyone will have permissions to do so
    # cause assuming this specific role must be allowed in management account 

    # Unfortunatelly, you can't specify a usergroup as a principal
    # so alternatively you can provide a list of IAM users who will be allowed to assume this role, instead of the whole account
    principals {
      type        = "AWS"
      identifiers = var.principals
    }

    effect = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = var.policy_arn
}
