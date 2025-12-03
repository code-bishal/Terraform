variable "ami_Id" {
  description = "Module description Resource"
}

variable "instance_type" {
  description = "Module description Resource"
  type        = map(string)

  default = {
    "dev"   = "t3.micro"
    "stage" = "m7i-flex.large"
    "prod"  = "c7i-flex.large"
  }
}

variable "subnet_id" {
  description = "Module description Resource"
}

variable "key_name" {
  description = "Module description Resource"
}

variable "s3_name" {
  description = "S3 bucket name"
}

variable "dynamo_db" {
  description = "Dynamo DB"
}



