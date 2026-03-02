# Security Group for MongoDB
resource "aws_security_group" "mongodb" {
  name_prefix = "${var.environment}-mongodb-sg-"
  description = "Security group for MongoDB instance"
  vpc_id      = var.vpc_id

  # MongoDB access from application servers
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [var.app_server_sg_id]
    description     = "Allow MongoDB from application servers"
  }

  # SSH access (optional, for management)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
    description = "Allow SSH for management"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.environment}-mongodb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for MongoDB EC2
resource "aws_iam_role" "mongodb" {
  name = "${var.environment}-mongodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.environment}-mongodb-role"
  }
}

# Attach CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.mongodb.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach SSM policy for Session Manager
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.mongodb.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "mongodb" {
  name = "${var.environment}-mongodb-profile"
  role = aws_iam_role.mongodb.name
}

# EBS Volume for MongoDB data
resource "aws_ebs_volume" "mongodb_data" {
  availability_zone = var.availability_zone
  size              = var.mongodb_volume_size
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${var.environment}-mongodb-data"
  }
}

# MongoDB EC2 Instance
resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.mongodb.id]
  iam_instance_profile   = aws_iam_instance_profile.mongodb.name
  key_name               = var.key_name != "" ? var.key_name : null

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    mongodb_version = var.mongodb_version
    db_username     = var.db_username
    db_password     = var.db_password
  })

  tags = {
    Name = "${var.environment}-mongodb-server"
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

# Attach EBS volume to instance
resource "aws_volume_attachment" "mongodb_data" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.mongodb_data.id
  instance_id = aws_instance.mongodb.id

  # Prevent volume from being deleted with instance
  skip_destroy = true
}
