# This file tells Terraform where to save the state file (remote backend).
# "backend" is where Terraform keeps the record of all resources.
# The "key" value is the name of the state file for this module.

terraform {
  backend "s3" {
    bucket = "project-team-07-tfstate"            # The S3 bucket name (must be already created)
    key    = "shared/terraform.tfstate"      # Unique state file for this module
    region = "eu-west-2"                     # AWS region
  }
}
