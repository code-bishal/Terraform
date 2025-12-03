#############################################
# PROVIDER CONFIGURATION
#############################################
# Tells Terraform to use AWS provider in us-east-1 region
provider "aws" {
  region = "us-east-1"
}

#############################################
# VPC CONFIGURATION
#############################################
# Creates a custom VPC using CIDR block defined in variables
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block

  # High-level purpose:
  # A VPC is your own private network in AWS.
}


#############################################
# PUBLIC SUBNETS (2 AZs)
#############################################

# Subnet-1 → AZ us-east-1a (PUBLIC)
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true  # EC2 gets a public IP

  # Purpose:
  # Public Subnets allow EC2 instances to be reachable from the internet.
  tags = { Name = "Subnet-1" }
}

# Subnet-2 → AZ us-east-1b (PUBLIC)
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "Subnet-2" }
}


#############################################
# INTERNET GATEWAY (Allows inbound/outbound internet)
#############################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  # Purpose:
  # Required for a VPC to communicate with the public Internet.
}


#############################################
# PUBLIC ROUTE TABLE
#############################################
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id

  # 0.0.0.0/0 means "internet"
  # Route internet traffic through IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "Route Table to Internet Gateway" }
}

# Attach Subnet-1 → Public Route Table
resource "aws_route_table_association" "Rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.public_route.id
}

# Attach Subnet-2 → Public Route Table
resource "aws_route_table_association" "Rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.public_route.id
}

#############################################
# SECURITY GROUP (Web SG)
#############################################
# Acts like a virtual firewall
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.vpc.id

  tags = { Name = "AWS Project" }
}

# Allow INBOUND HTTP from ANYWHERE
resource "aws_vpc_security_group_ingress_rule" "web_sg" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# Allow INBOUND SSH
resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

# Allow ALL OUTBOUND (Default behaviour)
resource "aws_vpc_security_group_egress_rule" "web_sg" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"   # -1 = all protocols / ports
}


#############################################
# EC2 INSTANCES
#############################################
# EC2 Instance 1 → In Subnet-1
resource "aws_instance" "EC2-1" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.sub1.id
  key_name               = "V Profile Key Pair"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = base64encode(file("userdata.sh"))

  tags = { Name = "Terraform Instances-1" }
}

# EC2 Instance 2 → In Subnet-2
resource "aws_instance" "EC2-2" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.sub2.id
  key_name               = "V Profile Key Pair"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = base64encode(file("userdata1.sh"))

  tags = { Name = "Terraform Instances-2" }
}



#############################################
# TARGET GROUP (Where EC2 Receives Traffic)
#############################################
resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80           # Forward traffic TO EC2 application port
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  # Health check configuration
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

# Register EC2-1 in Target Group
resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.EC2-1.id
  port             = 80
}

# Register EC2-2 in Target Group
resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.EC2-2.id
  port             = 80
}


#############################################
# APPLICATION LOAD BALANCER (ALB)
#############################################
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false                 # Public-facing ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]

  tags = { Environment = "AWS Project Load Balancer" }
}

#############################################
# ALB LISTENER (Receives user traffic)
#############################################

resource "aws_lb_listener" "lbListener" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80         # ALB listens on port 80
  protocol          = "HTTP"

  # Forward incoming traffic to target group
  default_action {
    target_group_arn = aws_lb_target_group.test.arn
    type             = "forward"
  }
}


#############################################
# OUTPUTS
#############################################
output "iDs" {
  value = {
    vpc_id            = aws_vpc.vpc.id
    igw               = aws_internet_gateway.igw.id
    sub1              = aws_subnet.sub1.id
    sub2              = aws_subnet.sub2.id
    security_group_id = aws_security_group.web_sg.id
    load_balancer_url = aws_lb.test.dns_name
    target_group_arn  = aws_lb_target_group.test.id
  }
}

# VPC FLOW

# # User → Internet → ALB (Public Subnet)
#                      ↓
#                 Route Table
#                      ↓
#                 Internet Gateway
#                      ↓
#                 Public Subnet
#                      ↓
#                    EC2
# 


# LOAD BALANCER FLOW


# User Browser  →  http://ALB-DNS:80
#        ⬇
# ALB Listener (port 80) catches request
#        ⬇
# Listener forwards → Target Group
#        ⬇
# Target Group selects EC2 instance (round robin)
#        ⬇
# Traffic sent to EC2:80 (your app)
#        ⬇
# EC2 responds → ALB → User
