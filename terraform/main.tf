terraform {
  required_providers {
    #TODO: aws will be a required provider here
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
  }
}
}
#TODO: add a 'provider' block for aws here
provider "aws" {
  region = "eu-west-2"
  profile = "test-account"
}


data "aws_s3_bucket" "ingestion-zone-007"{
  bucket="ingestion-zone-007"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}