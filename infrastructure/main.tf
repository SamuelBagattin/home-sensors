data "aws_caller_identity" "current" {}

provider "aws" {
  region  = "eu-west-1"
  profile = var.aws_profile
  default_tags {
    tags = {
      "Project" : "home-sensors"
    }
  }
}

terraform {
  required_version = ">=1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket  = "samuel-terraform-states"
    encrypt = "true"
    key     = "home-sensor.tfstate"
    region  = "eu-west-3"
  }
}
