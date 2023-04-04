terraform {
  required_version = "~> 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  /* backend "s3" {

    bucket = "secret-sns-tf-bucket"
    region = "ap-south-1"
  } */
}

provider "aws" {
  region  = "ap-south-1"
  profile = "default"

}

