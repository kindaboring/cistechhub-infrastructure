# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-rds-sg-"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  # Allow MySQL/Aurora access from web servers
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.web_server_sg_id]
    description     = "Allow MySQL from web servers"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.environment}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier             = "${var.environment}-database"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_type           = "gp3"
  storage_encrypted      = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az               = false  # Set to true for production
  publicly_accessible    = false
  skip_final_snapshot    = true  # Set to false for production
  backup_retention_period = 1  # Free Tier allows 0-1 days
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name = "${var.environment}-rds-instance"
  }
}
