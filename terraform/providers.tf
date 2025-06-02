# Define required providers and their version constraints for this Terraform configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Use any compatible version from 5.0 up to (but not including) 6.0
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"  # Use any compatible version from 3.0 up to (but not including) 4.0
    }
  }

  required_version = ">= 1.0"  # Ensure Terraform CLI version is 1.0 or higher
}

# Configure the AWS provider with the specified region and CLI profile
provider "aws" {
  region  = "eu-west-2"
  profile = "test-account"  # Use credentials from the "test-account" AWS CLI profile
}
