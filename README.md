# Prerequisites

- Terraform installed locally

- AWS cli installed locally

- Have 5 email address for `management`, `ci`, `dev`, `staging` and `prod` AWS accounts.

You can use a gmail hack where you can add a `+` after your email address and it will alias it to the originial one. `myproject+management@gmail.com`, `myproject+dev@gmail.com`, `myproject+ci@gmail.com`, `myproject+staging@gmail.com`, `myproject+prod@gmail.com`

# Setup

1. Create a fresh AWS account with the email address you chose for management account (`myproject+management@gmail.com`). Do this through AWS console. And login to this account as root user.

2. Go to IAM and create a user named `terraform-tmp` with `programmatic access` box checked. Attach existing policy `AdministratorAccess` directly to it. **Note down the Access key ID and Secret access key**

3. Configure/export the access key and secret access key for `terraform-tmp` user

4. Make sure you're making changes to the right AWS account. Execute this command to see who you are authenticated as

```
aws sts get-caller-identity
```

7. Clone this repository and cd into it

8. Remove origin

```
git remote remove origin
```

9. Set aws region and terraform state bucket name and information about AWS accounts and users

### Open `./main.tf`

- Change `aws-region` in `locals` to the region you want
- Change `terraform_state_bucket_name` to the bucket name that makes sense for your project. **Bucket name must be unique across all of AWS**
- Change `region` and `bucket` in `backend` configuration a few lines above to match the values you just set in `locals`. Keep backend configuration commented out for now
- Set `github_org` to your github organization name or your github username
- Set `github_app_repo` to the name of the repo with the app code
- Create an empty repo in the same github account/org and name it `terraform-org` (or anything else that makes sense to you)
- Set `github_terraform_repo` to the name of the empty repo for the terraform code we just created
- Set `XXX_account_name` and `XXX_account_root_email` emails for 4 AWS accounts. All names and emails must be distinct (Use the emails you prepared in prerequisites)

### Open `./users/users.tf`

- Set username and email for the AWS IAM user that will be created for yourself. By default this user will be given readonly access to all envs

10. Terraform init for the first time

```
terraform init
```

11. Terraform plan for the first time

We are providing `OrganizationAccountAccessRole` here so that terraform assumes it in each member account when making a change there. We need to do this because by default it will attempt to assume a different role that is available only to github repo.

```
terraform plan -var role_name_to_assume_in_member_accounts=OrganizationAccountAccessRole
```

12. Terraform apply for the first time

This will create:

### Terraform remote state storage

- S3 bucket for storing terraform state
- Dynamodb table for locking the state
- Secret in KMS for encypting data in s3

### Organization

- Organization in management account
- 4 member accounts: `dev`, `ci`, `staging`, `prod`

### Roles for github repos

- Github identity provider, so that you repo can assume role without storing credentials
- 2 roles with AdministratorAccess in each member account (`dev`, `ci`, `staging` and `prod`) that can be assumed by specific roles in management account
- 2 roles in management account for github repos that give permissions to assume roles in `dev`, `ci`, `staging` and `prod` with AdministratorAccess

### Other IAM

- Users
- Usergroups
- Associated permissions for cross-account access

```
terraform apply -var role_name_to_assume_in_member_accounts=OrganizationAccountAccessRole

-> Do you want to perform these actions?
yes
```

Note down the `app_repo_role_arn` and `terraform_repo_role_arn` in outputs `management_account` object after apply.

Also take a note of each AWS account id.

13. Uncomment the s3 backend provider code in `./main.tf`, cause now we created all infrastructure to be able to switch to new backend. Double check the value here match the ones a few lines beloew in `locals` in the same file

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    region         = "<YOUR_AWS_REGION>"
    bucket         = "terraform-state-for-<YOUR_GITHUB_ORG or USERNAME>-<YOUR_GITHUB_TERRAFORM_REPO_NAME>"
    dynamodb_table = "terraform-state-lock"
    kms_key_id     = "alias/terraform-bucket-key"

    key     = "org-shared-state/terraform.tfstate"
    encrypt = true
  }
}
```

14. Terraform init once again cause we're using new backend

```
terraform init

-> Do you want to copy existing state to the new backend?
yes
```

15. Just as a test, do terraform apply and see 0 changes

```
terraform apply -var role_name_to_assume_in_member_accounts=OrganizationAccountAccessRole
```

16. Open `./.github/workflows/apply-on-master.yml` and `./.github/workflows/plan-on-PR.yml` and in both of them

- set `ROLE_TO_ASSUME` to the `terraform_repo_role_arn` that terraform apply output gave you in step 12
- set `AWS_REGION` to the region that you set for terraform backend in `./main.tf`

17. Commit your code to `master`, add remote repository, and push to `master`

This step will push your code to the repo and in `Actions` tab on github you will see 2 github action appear

Note that repository name and org should match what you specified in `./main.tf`

```git
git add .
git commit -m "setup remote state and gh actions"

git remote add origin git@github.com:<YOUR_GITHUB_ORG or USERNAME>/<YOUR_GITHUB_TERRAFORM_REPO_NAME>.git
git push --set-upstream origin master
```

18. Add 5 AWS account IDs noted down in step 12 to the top of this README

Use the following format:

```
AWS management account:
  ID: <ACCOUNT_ID>
  Root email: <ROOT_EMAIL>


AWS dev account:
  ID: <DEV_ACCOUNT_ID>
  Root email: <DEV_ROOT_EMAIL>

AWS ci account:
  ID: <CI_ACCOUNT_ID>
  Root email: <CI_ROOT_EMAIL>

AWS staging account:
  ID: <STAGING_ACCOUNT_ID>
  Root email: <STAGING_ROOT_EMAIL>

AWS prod account ID:
  ID: <ACCOUNT_ID>
  Root email: <PROD_ROOT_EMAIL>
```

- create PR and merge

```
git checkout master
git pull
git checkout -b "add-aws-account-ids-to-readme"
git add .
git commit -m "added aws account ids"
git push --set-upstream origin add-aws-account-ids-to-readme
```

- Click on the link that git cli gives you to create PR
- See gh action run on the PR and plan
- See 0 changes in the plan
- Merge the PR
- See gh action run again on merge, this action should detect 0 changes as well in apply step

19. Delete the `terraform-tmp` user

- Login to AWS management account as root (if not already)
- Go to IAM
- delete `terraform-tmp` user
- delete/unset access key and secret key you used locally up to this point
- from this point you won't be able to apply terraform locally, the only way is via PR on github

20. Stop using root and start using IAM user

- Go to IAM
- Select the user terraform created after apply
- go to security credentials and manually create console login credentials for that user

- Save these credentials along with AWS account id to your password manager

- Create access key and secret key for this user and export/configure them locally

- Make sure you're now authenticated as the new IAM user and you are the right account

```
aws sts get-caller-identity
```

- Logout from root account in AWS console and login as the new IAM user. This is the IAM user account you should be using from now on

21. Configure cross-account access via AWS console

By default this user will have readonly access to all accounts. Through the console you will always login to management account. To see other accounts,you assume roles to those accounts from management account

Now we will setup quick readonly access to 4 member accounts

- On very the top right in AWS console, click on the dropdown

### Dev

- Click `switch role`
- Click another big `switch role` button if it is shown
- You are asked to enter 3 field values
  - Account - enter id of dev AWS account
  - Role - enter `readonly-role`
  - Display Name - enter `dev-readonly`
  - Select green color
  - Click `switch role`
- Now you are signed into dev account as readonly user
  Repeat the

### CI

- Repeat the same steps, display name - enter `ci-readonly`

### STAGING

- Repeat the same steps, display name - enter `staging-readonly`

### PROD

- Repeat the same steps, display name - enter `prod-readonly`. Select `orange` color to indicate it's `prod`

Now you should have 4 shortcuts in AWS console on the top right to quickly switch between accounts

To assume roles from AWS CLI refer to this guide: https://aws.amazon.com/premiumsupport/knowledge-center/iam-assume-role-cli/

In short, you would need to

- execute

```
aws sts assume-role --role-arn "arn:aws:iam::<ACCOUNT_ID>:role/readonly-role" --role-session-name=<YOUR_USERNAME>-readonly
```

- export temporary credentials from the output of the command above

```
export AWS_ACCESS_KEY_ID=RoleAccessKeyID
export AWS_SECRET_ACCESS_KEY=RoleSecretKey
export AWS_SESSION_TOKEN=RoleSessionToken
```

- verify you are authenticated in the right account with the right role

```
aws sts get-caller-identity
```

22. Create a test PR creating an S3 bucket

- Open `./accounts/dev/main.tf`
- Add an S3 bucket at bottom (note that the name should be unique across all AWS)

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-test-bucket-<YOUR_GITHUB_ORG or USERNAME>-<YOUR_GITHUB_TERRAFORM_REPO_NAME>" # or anything else unique accross whole AWS
}
```

- Create a PR with those changes

```
git checkout -b "add-my-first-test-bucket"
git add .
git commit -m "added my first bucket"
git push --set-upstream origin add-my-first-test-bucket
```

- Click on the link that git cli gives you to create PR

- See `Terraform Plan on PR` action automatically start on the PR. Once the action finishes it will create a comment on your PR where you can preview the result of `terraform plan`

- Merge the PR and see successful gh action run

- See `Terraform Apply on Master` action starting and succesfully completing

- Go to `dev` account in AWS console and verify the bucket was created there

- Go to `ci`, `staging` and `prod` accounts in AWS console and verify there's no buckets there

23. Create another PR to delete the test bucket

- Pull latest master and create a new branch off it

```
git checkout master
git pull
git checkout -b "remove-test-bucket"
```

- Open `./accounts/dev/main.tf` and remove the lines we added in step 22

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-test-bucket-<YOUR_GITHUB_ORG or USERNAME>-<YOUR_GITHUB_REPO>"
}
```

- Commit and create a PR

```
git add .
git commit -m "remove test bucket"
git push --set-upstream origin remove-test-bucket
```

- Click on the link that git cli gives you to create PR
- Wait until `Terraform Plan on PR` finishes and adds a comment to a PR to of with the plan that removes the bucket
- Merge pull request
- Wait until `Terraform Apply on Master` succeeds
- Verify the bucket is deleted from `dev` AWS account

# How to

## Use terraform locally

### terraform init

Works locally

### terraform validate

Works locally

### terraform plan

Works locally with extra flags

```
terraform plan -lock=false -var role_name_to_assume_in_member_accounts=readonly-role
```

- `-lock=false` means that when the dynamodb lock table is not gonna be used as developers don't have write permissions to it

- `role_name_to_assume_in_member_accounts=readonly-role` is specifying which role in member accounts should be used for terraform to read state to be able to `plan`

Ideally you wouldn't need to do that, but if you really need to there are 2 ways

### terraform apply

Doesn't work locally as developers don't have write permissions to all accounts by default.

There are 2 ways to make it work

#### 1. Adding admin rights in all member accounts to your current IAM user

- Add the IAM user you are using to `dev-admins` and `prod-admins` groups in terraform file `./users/users.rf`
- Create a PR
- See plan
- Merge the PR
- See it successfully aplied

- Now you can execute terraform apply locally:

```
terraform apply -var role_name_to_assume_in_member_accounts=OrganizationAccountAccessRole
```

#### 2. Create a temporary IAM user with AdministratorAccess

- Login to management AWS account as root user
- Create temporary IAM user with programmatic access enabled and `AdministratorAccess` policy attached
- Create access key and secret access key for that user
- Export/configure them locally
- Verify you're authenticated as the new temporary user

```
aws sts get-caller-identity
```

- all terraform operations will work now locally, including

```
terraform apply -var role_name_to_assume_in_member_accounts=OrganizationAccountAccessRole
```

- Delete the temporary IAM user once done
