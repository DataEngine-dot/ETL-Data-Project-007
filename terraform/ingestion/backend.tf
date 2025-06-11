# This backend is only for the ingestion module.
# Do not use the same key as any other module.

terraform {
  backend "s3" {
    bucket = "project-team-07-tfstate"                # Use the same S3 bucket as other modules
    key    = "ingestion/terraform.tfstate"       # Unique key for this module
    region = "eu-west-2"
  }
}