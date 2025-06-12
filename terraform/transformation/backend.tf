# This backend is only for the transformation module.
# Each module must have its own key.

terraform {
  backend "s3" {
    bucket = "project-team-07-tfstate"
    key    = "transformation/terraform.tfstate"
    region = "eu-west-2"
  }
}
