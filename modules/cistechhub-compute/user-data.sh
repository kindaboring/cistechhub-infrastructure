#!/bin/bash
set -e

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install jq for JSON parsing
yum install -y jq

# Install CloudWatch Agent
yum install -y amazon-cloudwatch-agent

# Create directory for application
mkdir -p /opt/cistechhub
cd /opt/cistechhub

# Fetch secrets from Secrets Manager
export AWS_DEFAULT_REGION=${aws_region}

# Get MongoDB credentials
MONGO_CREDS=$(aws secretsmanager get-secret-value --secret-id ${secrets_prefix}/mongodb-credentials --query SecretString --output text)
export MONGO_ROOT_USERNAME=$(echo $MONGO_CREDS | jq -r '.username')
export MONGO_ROOT_PASSWORD=$(echo $MONGO_CREDS | jq -r '.password')

# Get JWT secret
export JWT_SECRET=$(aws secretsmanager get-secret-value --secret-id ${secrets_prefix}/jwt-secret --query SecretString --output text)

# Get Grafana credentials
GRAFANA_CREDS=$(aws secretsmanager get-secret-value --secret-id ${secrets_prefix}/grafana-admin --query SecretString --output text)
export GF_SECURITY_ADMIN_USER=$(echo $GRAFANA_CREDS | jq -r '.username')
export GF_SECURITY_ADMIN_PASSWORD=$(echo $GRAFANA_CREDS | jq -r '.password')

# Try to get Google OAuth (optional)
GOOGLE_OAUTH=$(aws secretsmanager get-secret-value --secret-id ${secrets_prefix}/google-oauth --query SecretString --output text 2>/dev/null || echo '{}')
export GOOGLE_CLIENT_ID=$(echo $GOOGLE_OAUTH | jq -r '.client_id // empty')
export GOOGLE_CLIENT_SECRET=$(echo $GOOGLE_OAUTH | jq -r '.client_secret // empty')

# Create docker-compose.yml (without Ollama)
cat > docker-compose.yml <<'EOF'
services:
  web:
    image: kndaboring/cistechhub-web:latest
    expose:
      - "3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - auth-service
    restart: unless-stopped
    networks:
      - frontend
      - backend
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G

  auth-service:
    image: kndaboring/cistechhub-auth:latest
    expose:
      - "3001"
    environment:
      - NODE_ENV=production
      - MONGODB_URI=mongodb://${MONGO_ROOT_USERNAME}:${MONGO_ROOT_PASSWORD}@${mongodb_host}:27017/cistechhub?authSource=admin&retryWrites=true&w=majority
      - JWT_SECRET=${JWT_SECRET}
      - JWT_EXPIRES_IN=24h
      - GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
      - GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}
      - CORS_ORIGIN=http://localhost:3000
      - UPLOADS_DIR=/app/uploads
      - AWS_REGION=${aws_region}
      - S3_BUCKET=${uploads_bucket}
    restart: unless-stopped
    networks:
      - backend
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - web
      - auth-service
      - grafana
    networks:
      - frontend
      - backend
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=15d'
    networks:
      - backend
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3002:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD}
      - GF_SECURITY_ADMIN_USER=${GF_SECURITY_ADMIN_USER}
      - GF_SERVER_ROOT_URL=http://localhost:3002/grafana
      - GF_SERVER_SERVE_from_sub_path=true
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - backend
    restart: unless-stopped
    depends_on:
      - prometheus
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

volumes:
  grafana_data:
  prometheus_data:
EOF

# Create nginx configuration
cat > nginx.conf <<'EOF'
events {
    worker_connections 1024;
}

http {
    upstream web {
        server web:3000;
    }

    upstream auth {
        server auth-service:3001;
    }

    upstream grafana {
        server grafana:3000;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://web;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /api/auth {
            proxy_pass http://auth;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /grafana {
            proxy_pass http://grafana;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
EOF

# Create Prometheus configuration
cat > prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

# Save environment variables for docker-compose
cat > .env <<EOF
MONGO_ROOT_USERNAME=$MONGO_ROOT_USERNAME
MONGO_ROOT_PASSWORD=$MONGO_ROOT_PASSWORD
JWT_SECRET=$JWT_SECRET
GF_SECURITY_ADMIN_USER=$GF_SECURITY_ADMIN_USER
GF_SECURITY_ADMIN_PASSWORD=$GF_SECURITY_ADMIN_PASSWORD
GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET
EOF

# Start Docker Compose
docker-compose pull
docker-compose up -d

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/docker",
            "log_group_name": "/aws/ec2/cistechhub",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

echo "Cistechhub application setup completed!"
