# Security Group for All-in-One Server
resource "aws_security_group" "app_server" {
  name_prefix = "${var.environment}-cistechhub-sg-"
  description = "Security group for cistechhub all-in-one server"
  vpc_id      = var.vpc_id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  # HTTPS access from anywhere (for future use)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  # SSH access (restrict to your IP in production!)
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
    Name = "${var.environment}-cistechhub-sg"
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

# IAM Role for EC2
resource "aws_iam_role" "app_server" {
  name = "${var.environment}-cistechhub-role"

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
    Name = "${var.environment}-cistechhub-role"
  }
}

# Attach CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.app_server.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach SSM policy for Session Manager (alternative to SSH)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# S3 access policy for uploads
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
  name = "${var.environment}-cistechhub-profile"
  role = aws_iam_role.app_server.name
}

# Elastic IP
resource "aws_eip" "app_server" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-cistechhub-eip"
  }
}

# Generate random passwords
resource "random_password" "mongodb_password" {
  length  = 16
  special = false
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.app_server.id]
  iam_instance_profile   = aws_iam_instance_profile.app_server.name
  key_name               = var.key_name != "" ? var.key_name : null

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30  # Within free tier
    encrypted             = true
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    aws_region         = var.aws_region
    environment        = var.environment
    uploads_bucket     = var.uploads_bucket_name
    mongodb_username   = "cistechhub"
    mongodb_password   = random_password.mongodb_password.result
    jwt_secret         = random_password.jwt_secret.result
    google_client_id     = var.google_client_id
    google_client_secret = var.google_client_secret
    google_redirect_uri  = var.google_redirect_uri != "" ? var.google_redirect_uri : "http://${aws_eip.app_server.public_ip}/api/auth/google-callback"
    cors_origin          = "http://${aws_eip.app_server.public_ip}"
  })

  tags = {
    Name = "${var.environment}-cistechhub-server"
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
