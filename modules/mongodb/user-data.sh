#!/bin/bash
set -e

# Update system
yum update -y

# Install required packages
yum install -y amazon-cloudwatch-agent

# Configure MongoDB repository
cat > /etc/yum.repos.d/mongodb-org-${mongodb_version}.repo <<EOF
[mongodb-org-${mongodb_version}]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/${mongodb_version}/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-${mongodb_version}.asc
EOF

# Install MongoDB
yum install -y mongodb-org

# Wait for EBS volume to be attached
while [ ! -e /dev/xvdf ]; do
  echo "Waiting for EBS volume..."
  sleep 5
done

# Check if volume has a filesystem, if not create one
if ! blkid /dev/xvdf; then
  mkfs -t xfs /dev/xvdf
fi

# Create mount point and mount volume
mkdir -p /data/db
mount /dev/xvdf /data/db

# Add to fstab for persistence
echo "/dev/xvdf /data/db xfs defaults,nofail 0 2" >> /etc/fstab

# Set ownership
chown -R mongod:mongod /data/db

# Configure MongoDB
cat > /etc/mongod.conf <<EOF
# mongod.conf
storage:
  dbPath: /data/db
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

processManagement:
  timeZoneInfo: /usr/share/zoneinfo

security:
  authorization: enabled
EOF

# Start MongoDB
systemctl start mongod
systemctl enable mongod

# Wait for MongoDB to start
sleep 10

# Create admin user
mongosh admin --eval "
db.createUser({
  user: '${db_username}',
  pwd: '${db_password}',
  roles: [
    { role: 'root', db: 'admin' }
  ]
})
"

# Create cistechhub database and user
mongosh admin -u '${db_username}' -p '${db_password}' --eval "
use cistechhub;
db.createUser({
  user: 'cistechhub',
  pwd: '${db_password}',
  roles: [
    { role: 'readWrite', db: 'cistechhub' }
  ]
})
"

# Restart MongoDB to apply all configurations
systemctl restart mongod

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/mongodb/mongod.log",
            "log_group_name": "/aws/ec2/mongodb",
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

echo "MongoDB installation completed!"
