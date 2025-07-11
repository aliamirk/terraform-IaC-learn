
# RDS Subnet Group
resource "aws_db_subnet_group" "default" {
  name       = "default-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "Default RDS Subnet Group"
  }
}

# RDS Instance
resource "aws_db_instance" "database" {
  identifier              = "tf-mysql-db"
  engine                  = var.db_engine
  engine_version          = var.engine_version
  instance_class          = var.db_instance
  allocated_storage       = var.db_storage
  db_name                 = var.db_name # default database
  username                = var.db_username
  password                = var.db_password
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name

  tags = {
    Name = "TF-MySQL"
  }
}