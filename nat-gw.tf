# #EIP
# resource "aws_eip" "nginxserver-eip" {
#   instance = aws_instance.nginxserver.id
#   vpc      = true
# }

# ###EIP ASSOC.
# resource "aws_eip_association" "eip_assoc" {
#   instance_id   = aws_instance.nginxserver.id
#   allocation_id = aws_eip.nginxserver-eip.id
# }

# ##NAT
# resource "aws_nat_gateway" "nginx-natgw" {
#   allocation_id = aws_eip.nginxserver-eip.id
#   subnet_id     = data.aws_subnet.bastion-subnet-public.id

#   tags = merge(local.common_tags,
#     { Name = "nategw"
#   Application = "public" })

#   # To ensure proper ordering, it is recommended to add an explicit dependency
#   # on the Internet Gateway for the VPC.
#   depends_on = [data.aws_internet_gateway.default]
# }
