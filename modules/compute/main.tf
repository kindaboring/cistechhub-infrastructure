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

# Security Group for Web Server
resource "aws_security_group" "web_server" {
  name_prefix = "${var.environment}-web-sg-"
  description = "Security group for web server"
  vpc_id      = var.vpc_id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  # SSH access (restrict this in production!)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.environment}-web-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Instance - Web Server
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.web_server.id]
  key_name               = var.key_name != "" ? var.key_name : null

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              # Create a simple web page
              cat > /var/www/html/index.html <<'HTML'
              <!DOCTYPE html>
              <html>
              <head>
                  <title>AWS Terraform Learning Lab</title>
                  <style>
                      body {
                          font-family: Arial, sans-serif;
                          max-width: 800px;
                          margin: 50px auto;
                          padding: 20px;
                          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                          color: white;
                      }
                      .container {
                          background: rgba(255,255,255,0.1);
                          padding: 30px;
                          border-radius: 10px;
                          backdrop-filter: blur(10px);
                      }
                      h1 { margin-top: 0; }
                      .info {
                          background: rgba(255,255,255,0.2);
                          padding: 15px;
                          border-radius: 5px;
                          margin: 10px 0;
                      }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <h1>🚀 Congratulations!</h1>
                      <p>Your Terraform-managed EC2 instance is running!</p>
                      <div class="info">
                          <strong>Instance Details:</strong><br>
                          Hostname: $(hostname)<br>
                          IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)<br>
                          Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)<br>
                          Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)
                      </div>
                      <p>This infrastructure was created using Terraform! 🎉</p>
                  </div>
              </body>
              </html>
              HTML
              EOF

  tags = {
    Name = "${var.environment}-web-server"
  }
}
