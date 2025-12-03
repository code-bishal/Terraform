variable "ami_Id" {
    description = "Ubuntu 24"
}

variable "instance_type" {
    description = "INstance Type of the Resouces"
}

variable "subnet_id" {
  description = "SUbnet id for the ec2 instance"
}

variable "key_name" {
  description = "Key Pair value"
  default = "V Profile Key Pair"
}