provider "aws" {
    region = "us-east-1"
}

module "ec2_instance" {
 source = "./modules/ec2" 
 ami_Id = var.ami_Id
 instance_type = var.instance_type
 subnet_id = var.subnet_id
 key_name = var.key_name
}

module "aws_s3_bucket" {
    source = "./modules/s3"
    s3_name= var.s3_name  
}

# module "aws_dynamodb_table" {
#   source = "./modules/dynamo_db"
# }