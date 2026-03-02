# Secrets Manager for Application Configuration

# MongoDB credentials
resource "aws_secretsmanager_secret" "mongodb_credentials" {
  name        = "${var.environment}/cistechhub/mongodb-credentials"
  description = "MongoDB root credentials"

  tags = {
    Name = "${var.environment}-mongodb-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "mongodb_credentials" {
  secret_id = aws_secretsmanager_secret.mongodb_credentials.id
  secret_string = jsonencode({
    username = var.mongodb_username
    password = var.mongodb_password
    database = "cistechhub"
  })
}

# JWT Secret for Auth Service
resource "aws_secretsmanager_secret" "jwt_secret" {
  name        = "${var.environment}/cistechhub/jwt-secret"
  description = "JWT secret for authentication service"

  tags = {
    Name = "${var.environment}-jwt-secret"
  }
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = random_password.jwt_secret.result
}

# Google OAuth credentials (optional - can be set manually)
resource "aws_secretsmanager_secret" "google_oauth" {
  name        = "${var.environment}/cistechhub/google-oauth"
  description = "Google OAuth credentials"

  tags = {
    Name = "${var.environment}-google-oauth"
  }
}

resource "aws_secretsmanager_secret_version" "google_oauth" {
  count     = var.google_client_id != "" ? 1 : 0
  secret_id = aws_secretsmanager_secret.google_oauth.id
  secret_string = jsonencode({
    client_id     = var.google_client_id
    client_secret = var.google_client_secret
  })
}

# Grafana admin password
resource "aws_secretsmanager_secret" "grafana_admin" {
  name        = "${var.environment}/cistechhub/grafana-admin"
  description = "Grafana admin credentials"

  tags = {
    Name = "${var.environment}-grafana-admin"
  }
}

resource "random_password" "grafana_admin" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id = aws_secretsmanager_secret.grafana_admin.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.grafana_admin.result
  })
}

# IAM policy for EC2 to read secrets
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.environment}-cistechhub-secrets-access"
  description = "Allow EC2 instances to read Secrets Manager secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.mongodb_credentials.arn,
          aws_secretsmanager_secret.jwt_secret.arn,
          aws_secretsmanager_secret.google_oauth.arn,
          aws_secretsmanager_secret.grafana_admin.arn
        ]
      }
    ]
  })
}
