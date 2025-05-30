# Define required Terraform version and provider dependencies
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use AWS provider version 5.x
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0" # Use Random provider version 3.x
    }
  }

  required_version = ">= 1.0" # Require Terraform version 1.0 or higher
}

# Configure the AWS provider with a fixed region
provider "aws" {
  region = "eu-west-2" # Always use this AWS region
  profile = "test-account"
}
