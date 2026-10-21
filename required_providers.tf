terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.10.0"
    }
  }
  required_version = ">= 1.0"
}

terraform {
  backend "s3" {
    region = "us-east-1"
  }
}

provider "aws" {
  # Set to us-east-1 as this is where resources have to live
  # for the ACM certificate to be attached to CloudFront
  region = "us-east-1"
}
