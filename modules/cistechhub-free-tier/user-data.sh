#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting cistechhub installation..."

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /opt/cistechhub
cd /opt/cistechhub

# Create environment file
cat > .env <<EOF
MONGO_ROOT_USERNAME=${mongodb_username}
MONGO_ROOT_PASSWORD=${mongodb_password}
JWT_SECRET=${jwt_secret}
GOOGLE_CLIENT_ID=${google_client_id}
GOOGLE_CLIENT_SECRET=${google_client_secret}
GOOGLE_REDIRECT_URI=${google_redirect_uri}
CORS_ORIGIN=${cors_origin}
AWS_REGION=${aws_region}
S3_BUCKET=${uploads_bucket}
EOF

# Create docker-compose.yml optimized for t2.micro (1GB RAM)
cat > docker-compose.yml <<'COMPOSE_EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: cistechhub-mongodb
    environment:
      - MONGO_INITDB_ROOT_USERNAME=$${MONGO_ROOT_USERNAME}
      - MONGO_INITDB_ROOT_PASSWORD=$${MONGO_ROOT_PASSWORD}
      - MONGO_INITDB_DATABASE=cistechhub
    volumes:
      - mongodb_data:/data/db
      - ./mongo-init.js:/docker-entrypoint-initdb.d/mongo-init.js:ro
    command: ["--auth", "--wiredTigerCacheSizeGB", "0.25"]
    restart: unless-stopped
    networks:
      - backend
    deploy:
      resources:
        limits:
          memory: 256M
    healthcheck:
      test: mongosh --eval "db.adminCommand('ping')"
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  auth-service:
    image: kndaboring/cistechhub-auth:latest
    container_name: cistechhub-auth
    depends_on:
      mongodb:
        condition: service_healthy
    environment:
      - NODE_ENV=production
      - MONGODB_URI=mongodb://$${MONGO_ROOT_USERNAME}:$${MONGO_ROOT_PASSWORD}@mongodb:27017/cistechhub?authSource=admin
      - JWT_SECRET=$${JWT_SECRET}
      - JWT_EXPIRES_IN=24h
      - GOOGLE_CLIENT_ID=$${GOOGLE_CLIENT_ID}
      - GOOGLE_CLIENT_SECRET=$${GOOGLE_CLIENT_SECRET}
      - GOOGLE_REDIRECT_URI=$${GOOGLE_REDIRECT_URI}
      - CORS_ORIGIN=$${CORS_ORIGIN}
      - AWS_REGION=$${AWS_REGION}
      - S3_BUCKET=$${S3_BUCKET}
      - NODE_OPTIONS=--max-old-space-size=192
    restart: unless-stopped
    networks:
      - backend
    deploy:
      resources:
        limits:
          memory: 256M

  web:
    image: kndaboring/cistechhub-web:latest
    container_name: cistechhub-web
    depends_on:
      - auth-service
    environment:
      - NODE_ENV=production
      - NODE_OPTIONS=--max-old-space-size=192
    restart: unless-stopped
    networks:
      - frontend
      - backend
    deploy:
      resources:
        limits:
          memory: 256M

  nginx:
    image: nginx:alpine
    container_name: cistechhub-nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - web
      - auth-service
    restart: unless-stopped
    networks:
      - frontend
      - backend
    deploy:
      resources:
        limits:
          memory: 64M

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge

volumes:
  mongodb_data:
    driver: local
COMPOSE_EOF

# Create MongoDB initialization script
cat > mongo-init.js <<'MONGO_EOF'
db = db.getSiblingDB('cistechhub');

db.createCollection('users');
db.createCollection('sessions');

print('Database initialized successfully');
MONGO_EOF

# Create optimized nginx configuration
cat > nginx.conf <<'NGINX_EOF'
user nginx;
worker_processes 1;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 512;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss
               application/rss+xml font/truetype font/opentype
               application/vnd.ms-fontobject image/svg+xml;

    upstream web_backend {
        server web:3000;
    }

    upstream auth_backend {
        server auth-service:3001;
    }

    server {
        listen 80;
        server_name _;

        client_max_body_size 10M;

        # Main application
        location / {
            proxy_pass http://web_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }

        # Auth API
        location /api/auth {
            proxy_pass http://auth_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
NGINX_EOF

# Pull Docker images
echo "Pulling Docker images..."
docker-compose pull

# Start services
echo "Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Check service status
docker-compose ps

echo "Cistechhub installation completed!"
echo "Application should be available at: ${cors_origin}"
echo "MongoDB is running with authentication enabled"
echo ""
echo "Useful commands:"
echo "  View logs: cd /opt/cistechhub && docker-compose logs -f"
echo "  Restart services: cd /opt/cistechhub && docker-compose restart"
echo "  Stop services: cd /opt/cistechhub && docker-compose down"
echo "  Start services: cd /opt/cistechhub && docker-compose up -d"
