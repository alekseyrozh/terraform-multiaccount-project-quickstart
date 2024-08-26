# Description

This guide explains how to setup AWS account for starting a new project in AWS. The setup includes the following:

- Have 3 AWS accounts within an AWS organization:
  * `management` - manually created "parent" account for AWS Organization
  * `dev` - created via terraform
  * `prod`- created via terraform

- AWS SSO login for users and control permissions for users to each AWS account

- Configured permissions for your terraform github repo and your "app" github repo to be able to make changes in AWS accounts. This is achieved via [OpenID Connect setup for github](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

- Github actions that let you exeute `plan` and `apply`


# Prerequisites

## 3 email root addresses for AWS accounts
- myproject@gmail.com - root email for AWS management account (recommended to be @gmail.com rather than your custom domain, in case you move DNS nameservers to AWS and manage break it, you still want to have access to your management account via root email)
- aws.dev@myproject.com - root email for AWS dev account (can also be @gmail.com)
- aws.prod@myproject.com - root email for AWS prod account (can also be @gmail.com)

## User emails
Email for each of the user that needs access to AWS. That would be at least one email for yourself
- alex@myproject.com

## Easy way to get multiple email addresses
You can use a gmail hack where you can add a `+` after your email address and it will alias it to the originial one. For example:
`myproject+management@gmail.com`, `myproject+dev@gmail.com`, `myproject+prod@gmail.com`, `myproject+alex@gmail.com`

## Terraform CLI
You need to have Terraform CLI installed locally, preferrably via tfenv.

[Install tfenv with brew](https://formulae.brew.sh/formula/tfenv)

## AWS ClI
[Install AWS CLI with brew](https://formulae.brew.sh/formula/awscli)


# Setup

## First AWS account
- Manually create AWS account with myproject@gmail.com email and name this account `<myproject>-management`


- Go to IAM and manually create a new `terraform-tmp` user, give  it administrator access permissions and create programmatic access keys

- Create a new aws credentials profile locally in `~/.aws/credentials` like this:
```
[myproject-tmp]
aws_access_key_id = <access key id>
aws_secret_access_key = <secret access key>
region = <region>
```

* Check credentials are configured correctly by executing
```
AWS_PROFILE=myproject-tmp aws sts get-caller-identity
```

## Clone this repo 

* Clone this repository and cd into it

* Remove origin
`git remote remove origin`

## Configure accounts and repos

Open `./main.tf`

- Change terraform aws provider verison constrant to the latest. As of now it will be `version = "~> 5.0"` https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Change `aws-region` in `locals` to the region you want
- Change `terraform_state_bucket_name` to the bucket name that makes sense for your project. **Bucket name must be unique across all of AWS**
- Change `region` and `bucket` in `backend` configuration a few lines above to match the values you just set in `locals`. Keep backend configuration commented out for now
- Set `github_org` to your github organization name or your github username
- Set `github_app_repo` to the name of the repo with the app code
- Create an empty repo in the same github account/org and name it `<my-project>-terraform` (or anything else that makes sense to you)
- Set `github_terraform_repo` to the name of the empty repo for the terraform code we just created
- Set `XXX_account_name` and `XXX_account_root_email` emails for dev and pord AWS accounts. All names and emails must be distinct (Use the emails you prepared in prerequisites)

## Terraform init
- check you current terraform version is what you expect

```
terraform --version
```

- terraform init
```
AWS_PROFILE=myproject-tmp terraform init
```

this should generated `.terraform.lock.hcl` (not gitignored on purpose) and a `.terraform` folder which is gitignored

## Terraform plan
- Run terraform plan
```
AWS_PROFILE=myproject-tmp terraform plan -var role_name_to_assume_in_member_accounts=OrganizationAccountAccessRole
```

We are providing OrganizationAccountAccessRole here so that terraform assumes it in each member account when making a change there. We need to do this because by default it will attempt to assume a different role that only github repo can assume

## Terraform apply

- Run terraform apply
```
AWS_PROFILE=myproject-tmp terraform apply -var role_name_to_assume_in_member_accounts=OrganizationAccountAccessRole`
```

* Note down the terraform output, which should inlcude `app_repo_role_arn` and `terraform_repo_role_arn` and ids for 3 AWS accounts

Now you have created `dev` and `prod` AWS accounts which are a part of the same AWS organisation with the `management` account being the parent. All billing is consolidated into the `management` account, it also holds all the AWS users in its SSO (IAM Identity Center) config. 

This should have also created a local `terraform.tfstate` file, which is gitignored. In the next step we will move this state into an S3 bucket.

## Move local terraform state to the S3 bucket

* Uncomment the S3 backend provider code in `./main.tf`, cause now we created all the needed infrastructure to be able to switch to remote backend. Double check the values here match the ones a few lines below it in locals in the same file

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    region         = "<YOUR_AWS_REGION>"
    bucket         = "terraform-state-for-<YOUR_PROJECT>"
    dynamodb_table = "terraform-state-lock"
    kms_key_id     = "alias/terraform-bucket-key"

    key     = "org-shared-state/terraform.tfstate"
    encrypt = true
  }
}
```

* Terraform init once again with the new backend setup
```
AWS_PROFILE=myproject-tmp terraform init


-> Do you want to copy existing state to the new backend?
yes
```

* For a piece of mind do terraform apply and see 0 changes
```
AWS_PROFILE=myproject-tmp terraform apply -var role_name_to_assume_in_member_accounts=OrganizationAccountAccessRole
```

Now the state from the local `terraform.tfstate` file was moved to the S3 and this local file should be empty now

## Enable SSO (IAM Identity Center)
IAM Identity Center is a preferred way to manage AWS users compared to normal IAM users. This plays well with the multiaccount setup as it simplifies the way to jump between accounts. Sadly not everything can be configured via terraform and a few manual steps are required

- Go to AWS console -> IAM Identity Center -> Click "Enable" -> (if prompted enable with AWS Organizations) -> Continue
- Manually edit “AWS access portal URL” to match your domain. Note down this link, it is used to login into AWS console via SSO. (The new link might take a bit of time to start working)
- (optional) Disable MFA -> Configure multi-factor authentication (MFA) -> Never -> Save

## Configure users

Open `./modules/sso/users.tf`

- Fill out user data and which users have dev and prod access.
  - `developers` group will give admin access to dev account and readonly access to prod and management accounts
  - `prod_admins` group will additionally give admin access to prod and management accounts

- go to `./main.tf` and uncomment the `sso` module at the bottom

- run terraform apply
```
AWS_PROFILE=myproject-tmp terraform apply -var role_name_to_assume_in_member_accounts=OrganizationAccountAccessRole
```

- After terraform is applied, go to AWS console -> IAM Identity Center and for each user and click “verify email” for the confirmation to be sent

- In the same place, for each user reset the password by either generating a one-time password or selecting an option to send email with instructions

## Login via SSO
Stop using root email and switch to SSO login instead

- Logout from AWS account

- go to the SSO login url you previously noted `https://<MY_PROJECT>.awsapps.com/start`

- use the username and password for your own AWS user that you have previously created in terraform code and reset the password for

- now you can select the account to login to, select `<myproject>-dev`, this will be needed for a later step

## Github Actions
Open all yamls in `./.github/workflows` and for all of them

- set `ROLE_TO_ASSUME` to the `terraform_repo_role_arn` that terraform apply output gave you previously

- set `AWS_REGION` to the region that you set for terraform backend in `./main.tf`

## Push to git
- Commit your code to `master`
```
git add .
git commit -m "setup remote state and gh actions"
```
- Add `<my-project>-terraform` repository that you created in one of the previous steps as a remote
```
git remote add origin git@github.com:<YOUR_GITHUB_ORG or USERNAME>/<YOUR_GITHUB_TERRAFORM_REPO_NAME>.git
```

- Push
```
git push --set-upstream origin master
```

## Create a test PR
- Create a new branch
```
git checkout -b "add-my-first-test-bucket"
```

In `./accounts/dev/main.tf`
- Add an S3 bucket at bottom (note that the name should be unique across all AWS)
```
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-test-bucket-<YOUR_GITHUB_ORG or USERNAME>-<YOUR_GITHUB_TERRAFORM_REPO_NAME>" # or anything else unique accross whole AWS
}
```

- Commit these changes to a branch and push 
```
git add .
git commit -m "added my first bucket"
git push --set-upstream origin add-my-first-test-bucket
```

- Create a PR by clicking on the link that git cli gives you

## Verify Github Actions

- See `Terraform Plan on PR` action automatically start on the PR. Once the action finishes it will create a comment on your PR where you can preview the result of `terraform plan`, 

- Merge the PR and see `Terraform Apply on Master` action starting and succesfully completing

- Go to `dev` account in AWS console and verify the bucket was created there

- You can repeat the steps by create another PR to delete this test bucket

## Delete the terraform-tmp user

- go to SSO login link previosly noted and login to the management account

- go to IAM and delete the `terraform-tmp` user manually created at the very start of this guide


## Update README and setup local access

This is it, now you can delete all the instructions above this one and use the below template for readme that this repository should have. Replace all the `<ACCOUNT_ID>`, `<ROOT_EMAIL>` and  `<YOUR_PROJECT>` with real values so that it's easier to refer to in the future. Also follow the below instructions to setup AWS CLI access to all the accounts via profiles

======= README TEMPLATE START =======

This repo and AWS accounts were setup following [starter project instructions](https://github.com/alekseyrozh/terraform-multiaccount-project-quickstart)

# AWS Accounts
```
AWS management account:
  ID: <ACCOUNT_ID>
  Root email: <ROOT_EMAIL>

AWS dev account:
  ID: <ACCOUNT_ID>
  Root email: <ROOT_EMAIL>

AWS prod account ID:
  ID: <ACCOUNT_ID>
  Root email: <ROOT_EMAIL>
```

# How to get access to AWS

### Login to AWS console
https://<YOUR_PROJECT>.awsapps.com/start


### Setup local access to AWS
Add this to `~/.aws/config`
```
[sso-session <YOUR_PROJECT>]
sso_region = eu-central-1
sso_start_url = https://<YOUR_PROJECT>.awsapps.com/start
sso_registration_scopes = sso:account:access
```

Add this to `~/.aws/credentials`
```
; this profile is enough for doing dev stuff

[<YOUR_PROJECT>-dev]
sso_session = <YOUR_PROJECT>
sso_account_id = <DEV_AWS_ACCOUNT_ID>
sso_role_name = AdministratorAccess


; don't add this, unless you really need it

[<YOUR_PROJECT>-prod]
sso_session = <YOUR_PROJECT>
sso_account_id = <PROD_AWS_ACCOUNT_ID>
sso_role_name = AdministratorAccess


; don't add this, unless you really need it

[<YOUR_PROJECT>-management]
sso_session = <YOUR_PROJECT>
sso_account_id = <MANAGEMENT_AWS_ACCOUNT_ID>
sso_role_name = AdministratorAccess
```


And then execute, which should redirect you to the browser login, this command might need to be repeated every time the login expires
```
aws sso login --sso-session <YOUR_PROJECT>
```

# How to make terraform changes

The simplest way to make change is to create a PR, wait for gh action to automatically add a comment with the results of `plan`. if you happy with it,merge the PR and `apply` will automatically execute. Additionally you can execute `apply` from a branch or from master manually by manually kicking off `Manual Terraform Apply on Branch` gh action and selecting the branch there.

# How to run terraform locally
To be able to execute terraform commands locally you most likely need to have access to all AWS accounts. `init` and `plan` might require readonly access only, while `apply` will required write access to accounts. The below commands assume you have `<YOUR_PROJECT>-management` profile setup with enough permissions.


### Terraform init
```
AWS_PROFILE=<YOUR_PROJECT>-management terraform init
```

### Terraform plan
```
AWS_PROFILE=<YOUR_PROJECT>-management terraform plan -lock=false -var role_name_to_assume_in_member_accounts=OrganizationAccountAccessRole
```

### Terraform apply
```
AWS_PROFILE=<YOUR_PROJECT>-management terraform apply -var role_name_to_assume_in_member_accounts=OrganizationAccountAccessRole
```

### Terraform format
```
terraform fmt
```