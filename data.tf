data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.bucket
    key    = "vpc/${var.ENV}/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "frontend" {
  backend = "s3"
  config = {
    bucket = var.bucket
    key    = "frontend/${var.ENV}/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "ami" {
  most_recent      = true
  name_regex       = "^Centos-7-DevOps-Practice"
  owners           = ["973714476881"]
}
