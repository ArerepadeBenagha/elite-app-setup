# #EC2-SG
# resource "aws_security_group" "ec2-sg" {
#   vpc_id      = aws_vpc.main.id
#   name        = "public web ngnix sg"
#   description = "security group Ec2-server"
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     security_groups = [aws_security_group.main-alb.id]
#   }
#   ingress {
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.main-alb.id]
#   }
#   tags = merge(local.common_tags,
#   { Name = "Ec2 security group" })
# }

# #ALB-SG
# resource "aws_security_group" "main-alb" {
#   vpc_id      = aws_vpc.main.id
#   name        = "public web allow"
#   description = "security group for ALB"
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = merge(local.common_tags,
#   { Name = "Alb security group" })
# }