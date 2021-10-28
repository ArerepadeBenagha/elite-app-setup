# resource "aws_db_subnet_group" "mariadb-subnet" {
#   name        = var.db_name_subnet
#   description = "RDS subnet group"
#   subnet_ids  = [aws_subnet.main-private-1.id, aws_subnet.main-private-2.id]
# }

# resource "aws_db_parameter_group" "mariadb-parameters" {
#   name        = var.db_parameters
#   family      = var.family
#   description = "MariaDB parameter group"

#   parameter {
#     name      = "max_allowed_packet"
#     value     = "16777216"
#   }
# }

# resource "aws_db_instance" "mariadb" {
#   allocated_storage       = var.storage # 100 GB of storage, gives us more IOPS than a lower number
#   engine                  = var.engine
#   engine_version          = var.engine_version
#   instance_class          = var.class # use micro if you want to use the free tier
#   identifier              = "mariadb"
#   name                    = var.db_name
#   username                = var.username           # username
#   password                = var.RDS_PASSWORD # password
#   db_subnet_group_name    = aws_db_subnet_group.mariadb-subnet.name
#   parameter_group_name    = aws_db_parameter_group.mariadb-parameters.name
#   multi_az                = var.multi_az # set to true to have high availability: 2 instances synchronized with each other
#   vpc_security_group_ids  = [aws_security_group.allow-mariadb.id]
#   storage_type            = var.storage_type
#   backup_retention_period = 30                                          # how long you’re going to keep your backups
#   availability_zone       = aws_subnet.main-private-1.availability_zone # prefered AZ
#   skip_final_snapshot     = true                                        # skip final snapshot when doing terraform destroy
#   tags = {
#     Name = "mariadb-instance"
#   }
# }