provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = var.s3_name

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}