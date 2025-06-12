# This backend is only for the warehouse_loader module.
# Do not copy the key from other modules.

terraform {
  backend "s3" {
    bucket = "project-team-07-tfstate"
    key    = "warehouse_loader/terraform.tfstate"
    region = "eu-west-2"
  }
}
