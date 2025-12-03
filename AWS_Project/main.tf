provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-1"
  }
}

resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Route Table to Internet Gateway"
  }
}

resource "aws_route_table_association" "Rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "Rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_instance" "EC2-1" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.sub1.id
  key_name               = "V Profile Key Pair"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = base64encode(file("userdata.sh"))

  tags = {
    Name = "Terraform Instances-1"
  }

}

resource "aws_instance" "EC2-2" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.sub2.id
  key_name               = "V Profile Key Pair"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = base64encode(file("userdata1.sh"))

  tags = {
    Name = "Terraform Instances-2"
  }

}

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "AWS Project Security Group "
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "AWS Project"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_sg" {
  security_group_id = aws_security_group.web_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_egress_rule" "web_sg" {
  security_group_id = aws_security_group.web_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id = aws_security_group.web_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.EC2-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.EC2-2.id
  port             = 80
}


resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]

  tags = {
    Environment = "AWS Project Load Balancer"
  }
}

resource "aws_lb_listener" "lbListener" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.test.arn
    type             = "forward"
  }

}
output "iDs" {

  value = {
    vpc_id            = aws_vpc.vpc.id
    igw               = aws_internet_gateway.igw.id
    sub1              = aws_subnet.sub1.id
    sub2              = aws_subnet.sub2.id
    security_group_id = aws_security_group.web_sg.id
    load_balancer_url = aws_lb.test.dns_name
    target_group_arn  = aws_lb_target_group.test.id


    # private_ip = aws_instance.demo_ec2.private_ip
  }
}
