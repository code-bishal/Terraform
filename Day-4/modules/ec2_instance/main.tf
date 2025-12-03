provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "module_ec2" {

    ami = var.ami_Id
    instance_type = var.instance_type
    subnet_id = var.subnet_id
    key_name = var.key_name
    
}