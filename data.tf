data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


########------- Bastion-SG -------------##########
data "aws_security_group" "bastion-sg" {
  id = "sg-0dda1d8ebfac503f0"
}
data "aws_subnet" "bastion-subnet-public" {
  id = "subnet-01c04b746a464ca8a"
}
data "aws_subnet" "bastion-subnet" {
  id = "subnet-07b7ef9b7829d5fb9"
}

##ALB-SG

data "aws_security_group" "alb-sg" {
  id = "sg-0d4e0e12d33ec2a9b"
}
data "aws_subnet" "alb-public-1" {
  id = "subnet-01c04b746a464ca8a"
}
data "aws_subnet" "alb-public-2" {
  id = "subnet-02d4d017f7a2d462d"
}

###VPC
data "aws_vpc" "vpc-stack" {
  id = "vpc-0903f5b0a7dcc45d3"
}