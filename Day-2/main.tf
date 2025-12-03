provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "demo_ec2" {
  
  ami  = var.ami_Id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  key_name  = var.key_name

  tags = {
    Name = "Terraform Instances"
  }
}

output "instance_ips" {

  value = {
    public_ip = aws_instance.demo_ec2.public_ip
    private_ip = aws_instance.demo_ec2.private_ip
  }
}
