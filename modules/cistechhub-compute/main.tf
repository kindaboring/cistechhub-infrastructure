# Security Group for Application Server
resource "aws_security_group" "app_server" {
  name_prefix = "${var.environment}-cistechhub-app-sg-"
  description = "Security group for cistechhub application server"
  vpc_id      = var.vpc_id

  # HTTP from ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "Allow HTTP from ALB"
  }

  # Prometheus from ALB (for monitoring access)
  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "Allow Prometheus from ALB"
  }

  # Grafana from ALB
  ingress {
    from_port       = 3002
    to_port         = 3002
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "Allow Grafana from ALB"
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
    Name = "${var.environment}-cistechhub-app-sg"
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

# IAM Role for Application Server
resource "aws_iam_role" "app_server" {
  name = "${var.environment}-cistechhub-app-role"

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
    Name = "${var.environment}-cistechhub-app-role"
  }
}

# Attach policies
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.app_server.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.app_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.app_server.name
  policy_arn = var.secrets_policy_arn
}

# S3 access policy
resource "aws_iam_role_policy" "s3_access" {
  name = "${var.environment}-s3-access"
  role = aws_iam_role.app_server.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.uploads_bucket_arn,
          "${var.uploads_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Instance profile
resource "aws_iam_instance_profile" "app_server" {
  name = "${var.environment}-cistechhub-app-profile"
  role = aws_iam_role.app_server.name
}

# Elastic IP
resource "aws_eip" "app_server" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-cistechhub-app-eip"
  }
}

# Application Server EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.app_server.id]
  iam_instance_profile   = aws_iam_instance_profile.app_server.name
  key_name               = var.key_name != "" ? var.key_name : null

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    aws_region       = var.aws_region
    environment      = var.environment
    mongodb_host     = var.mongodb_host
    uploads_bucket   = var.uploads_bucket_name
    secrets_prefix   = "${var.environment}/cistechhub"
  })

  tags = {
    Name = "${var.environment}-cistechhub-app-server"
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

# Associate EIP with instance
resource "aws_eip_association" "app_server" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.app_server.id
}

# Register instance with ALB target group
resource "aws_lb_target_group_attachment" "app_server" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.app_server.id
  port             = 80
}
