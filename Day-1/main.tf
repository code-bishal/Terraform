provider "aws" {
    region="us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0360c520857e3138f"
  instance_type = "t3.micro"
  subnet_id = "subnet-0a816c001f9328057"
  key_name = "V Profile Key Pair"

  tags = {
    Name = "Terraform Instances"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "my-tf-test-bucket-hifi-wifi-etc-123456"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}