terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket = "amzn-bitoasis-candidate-bucket"
    key = "assessment.tfstate"
    region = "us-east-2"
  }
}


# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}


