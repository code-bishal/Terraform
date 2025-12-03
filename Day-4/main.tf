provider "aws" {
    region = "us-east-1"
}

module "ec2_instance" {
 source = "./modules/ec2_instance" 
 ami_Id = var.ami_Id
 instance_type = lookup(var.instance_type,terraform.workspace,"t2.micro")
 subnet_id = var.subnet_id
 key_name = var.key_name
}

# module "aws_s3_bucket" {
#     source = "./modules/s3"
#     s3_name= var.s3_name  
# }

# module "aws_dynamodb_table" {
#   source = "./modules/dynamo_db"
# }