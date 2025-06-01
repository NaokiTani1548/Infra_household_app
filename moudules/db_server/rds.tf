# ---------------------------------------------
# RDS parameter groupe
# ---------------------------------------------
resource "aws_db_parameter_group" "mysql_standalone_parametergroup" {
  name   = "${var.project}-${var.env}-mysql-standalone-parametergroup"
  family = "mysql8.0"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

# ---------------------------------------------
# RDS option groupe
# ---------------------------------------------
resource "aws_db_option_group" "mysql_standalone_optiongroup" {
  name                 = "${var.project}-${var.env}-mysql-standalone-optiongroup"
  engine_name          = "mysql"
  major_engine_version = "8.0"
}

# ---------------------------------------------
# RDS subnet groupe
# ---------------------------------------------
resource "aws_db_subnet_group" "mysql_standalone_subnetgroup" {
  name = "${var.project}-${var.env}-mysql-standalone-subnetgroup"
  subnet_ids = [
    var.private1CID,
    var.private2CID
  ]

  tags = {
    Name        = "${var.project}-${var.env}-mysql-standalone-subnetgroup"
    Project     = var.project
    Environment = var.env
  }

}

# ---------------------------------------------
# RDS instance
# ---------------------------------------------
resource "random_string" "db_password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "mysql_standalone" {
  engine         = "mysql"
  engine_version = "8.0.36"
  identifier     = "${var.project}-${var.env}-mysql-standalone"
  username       = "admin"
  password       = random_string.db_password.result

  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp2"
  storage_encrypted     = false

  multi_az               = false
  availability_zone      = "ap-northeast-1c"
  db_subnet_group_name   = aws_db_subnet_group.mysql_standalone_subnetgroup.name
  vpc_security_group_ids = [var.db_sg_id]
  publicly_accessible    = false
  port                   = 3306

  name              = "household_budget"
  parameter_group_name = aws_db_parameter_group.mysql_standalone_parametergroup.name
  option_group_name    = aws_db_option_group.mysql_standalone_optiongroup.name

  backup_window              = "04:00-05:00"
  backup_retention_period    = 7
  maintenance_window         = "Mon:05:00-Mon:08:00"
  auto_minor_version_upgrade = false

  deletion_protection = false  # 削除時：false 復活時：true
  skip_final_snapshot = true # 削除時：true　復活時：false
  apply_immediately   = true

  tags = {
    Name        = "${var.project}-${var.env}-mysql-standalone"
    Project     = var.project
    Environment = var.env
  }

}