terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.37"
    }
  }

  backend "s3" {
    # bucket = "roboshopp-remote-state"  # changed from "roboshopp-remote-state"
    bucket = "roboshopp-remote-statee"
    key = "catalogue-dev"
    region = "us-east-1"
    dynamodb_table = "roboshop-locking" # DynamoDB table used for state locking to prevent concurrent modifications
  }
}

provider "aws" {
  # Configuration options
  # you can give access key and secret key, but there is security problem because we are going to -
  # - commit this into GitHub so unauthorized users may access 
  # by mistake if you push AWS access and secret key's to Github immediately get an email from Github to delete
  # region = "us-east-1"
  region = "us-east-1"
}