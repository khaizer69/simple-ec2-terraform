terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
 region ="us-east-1"
}

# This code block allows us to create an ec2 instance with hardcoded values
resource "aws_instance" "sample_ec2_hardcoded" {
  ami           = "ami-0b72821e2f351e396"
  instance_type = "t2.micro"
  key_name      = "khai keys" # Replace key_name with your own keypair name in the corresponding region
  subnet_id     = "subnet-09acf5721004f526c" # Replace subnet_id with your own vpc's subnet id (see Subnets in AWS console)
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "khai-webserver-terraform" # Replace Name with your own preferred EC2 instance name
  }
}

# This code block allows us to create an ec2 instance with the use of variables
# To overwrite any one particular variable, we can pass the variable at runtime during terraform apply step
# e.g. terraform apply --var ec2_name="my-var-webserver"
resource "aws_instance" "sample_ec2_variables" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = data.aws_subnet.selected_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = var.ec2_name
  }
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-0b72821e2f351e396"
}

variable "ec2_name" {
  description = "Name of EC2"
  type        = string
  default     = "my-sample-ec2-khai-from-tf" # Replace with your preferred EC2 Instance Name 
}

variable "instance_type" {
  description = "EC2 Instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of EC2 Key Pair"
  type        = string
  default     = "khai keys" # Replace with your own key pair name (without .pem extension) that you have downloaded from AWS console previously
}

variable "sg_name" {
  description = "Name of EC2 security group"
  type        = string
  default     = "khai-ec2-allow-ssh-http-https" # Replace with your own preferred security group name that gives an overview of the security group coverage
}

variable "vpc_name" {
  description = "Name of VPC to use"
  type        = string
  default     = "khai-vpc" # Update with your own VPC name, found under VPC > your VPC > Tags > value of Name
}

variable "subnet_name" {
  description = "Name of subnet to use"
  type        = string
  default     = "khai-subnet-public1-us-east-1a" # Update with your own Subnet name, found under VPC > your VPC > selected Public Subnet > tags > value of Name
}

# Creates a security group that allows us to create 
# ingress rules allowing traffic for HTTP, HTTPS and SSH protocols from anywhere
# You may add additional ingress rules if you would like to expose your EC2
# from other ports and protocols
resource "aws_security_group" "ec2_sg" {
  name   = var.sg_name
  vpc_id = data.aws_vpc.selected_vpc.id # var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.1/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.1/16"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.1/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Uses an existing VPC, filtered by vpc_name defined in variables.tf
data "aws_vpc" "selected_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Uses an existing subnet, filtered by subnet_name defined in variables.tf
data "aws_subnet" "selected_subnet" {
  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
}

# Comment out the below if you are working on local

terraform {
  backend "s3" {
    bucket = "sctp-ce7-tfstate" 
    key    = "terraform-ex-ec2-khai.tfstate" # Replace the value of key to <your suggested name>.tfstate for example terraform-ex-ec2-<NAME>.tfstate
    region = "us-east-1"
  }
}