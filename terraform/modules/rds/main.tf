resource "aws_db_subnet_group" "default" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = var.subnet_ids
  
  tags = {
    Name        = "${var.project_name}-db-subnet-group-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_db_instance" "mysql" {
  identifier             = "${var.project_name}-db-${var.environment}"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = var.security_groups
  publicly_accessible    = false
  skip_final_snapshot    = true
  
  # 小規模構成の場合のコスト削減オプション
  storage_type           = "gp2"
  backup_retention_period = 7
  multi_az               = var.environment == "prod"   # 本番環境のみMulti-AZ
  
  # パラメータグループの設定
  parameter_group_name   = aws_db_parameter_group.mysql.name
  
  tags = {
    Name        = "${var.project_name}-db-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
  
  lifecycle {
    # 意図しないパスワード変更を防止
    ignore_changes = [password]
  }
}

# MySQLパラメータグループの設定
resource "aws_db_parameter_group" "mysql" {
  name   = "${var.project_name}-mysql-params-${var.environment}"
  family = "mysql8.0"
  
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  
  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
  
  parameter {
    name  = "max_connections"
    value = var.environment == "prod" ? "100" : "50"
  }
  
  tags = {
    Name        = "${var.project_name}-mysql-params-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}