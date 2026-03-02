# Cistechhub AWS Deployment Guide

Complete step-by-step guide for deploying Cistechhub to AWS.

## Pre-Deployment Checklist

- [ ] AWS account created and verified
- [ ] AWS CLI installed and configured
- [ ] Terraform installed (v1.0+)
- [ ] (Optional) Ansible installed
- [ ] (Optional) EC2 key pair created
- [ ] Your public IP address identified

## Step-by-Step Deployment

### 1. AWS Account Setup

#### Create AWS Account

1. Go to https://aws.amazon.com
2. Click "Create an AWS Account"
3. Follow the registration process
4. **Important**: Enable MFA for root account security

#### Configure AWS CLI

```bash
# Install AWS CLI (if not already installed)
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure credentials
aws configure
# Enter your:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Output format (json)
```

#### Create IAM User for Terraform (Best Practice)

```bash
# Create IAM user
aws iam create-user --user-name terraform-user

# Attach admin policy (for learning purposes)
aws iam attach-user-policy \
  --user-name terraform-user \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access key
aws iam create-access-key --user-name terraform-user

# Save the Access Key ID and Secret Access Key
# Update ~/.aws/credentials with these credentials
```

### 2. Create EC2 Key Pair (Optional)

```bash
# Create key pair
aws ec2 create-key-pair \
  --key-name cistechhub-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/cistechhub-key.pem

# Set correct permissions
chmod 400 ~/.ssh/cistechhub-key.pem

# Verify key was created
aws ec2 describe-key-pairs --key-names cistechhub-key
```

**Note**: If you skip this step, you can still access your instance using AWS Systems Manager Session Manager.

### 3. Get Your Public IP Address

```bash
# Find your public IP
curl ifconfig.me

# Or
curl icanhazip.com

# Note this IP address - you'll need it for SSH security
```

### 4. Configure Terraform

```bash
# Navigate to cistechhub environment
cd cloud-sandbox/environments/cistechhub

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
nano terraform.tfvars
```

#### Edit terraform.tfvars

```hcl
# AWS Configuration
aws_region  = "us-east-1"  # or your preferred region
environment = "dev"

# EC2 Configuration
instance_type = "t2.micro"  # FREE TIER

# SSH Key Pair
key_name = "cistechhub-key"  # or leave empty to skip SSH

# IMPORTANT: Set your IP address!
ssh_allowed_cidrs = [
  "YOUR.IP.ADDRESS/32"  # Replace with actual IP from step 3
]

# Optional: Google OAuth (for social login)
# google_client_id     = "your-client-id.apps.googleusercontent.com"
# google_client_secret = "your-client-secret"
```

### 5. Initialize Terraform

```bash
# Initialize Terraform (download providers and modules)
terraform init

# You should see:
# "Terraform has been successfully initialized!"
```

### 6. Review Deployment Plan

```bash
# Generate and review execution plan
terraform plan

# Review the output carefully:
# - Check that resources will be created (not destroyed)
# - Verify instance type is t2.micro
# - Confirm VPC and subnet configurations
# - Note the estimated costs (should be $0 in free tier)
```

### 7. Deploy Infrastructure

```bash
# Deploy all resources
terraform apply

# Review the plan again
# Type 'yes' when prompted

# Deployment takes ~2-3 minutes
```

**Expected Output:**
```
Apply complete! Resources: 15+ added, 0 changed, 0 destroyed.

Outputs:

application_url = "http://XX.XX.XX.XX"
instance_id = "i-xxxxxxxxxxxxx"
public_ip = "XX.XX.XX.XX"
...
```

### 8. Wait for Application Setup

**Important**: After Terraform completes, the application still needs 5-10 minutes to:
- Install Docker and Docker Compose
- Pull Docker images
- Start all services

#### Monitor Progress

```bash
# Get SSH command
terraform output ssh_command

# SSH to server
ssh -i ~/.ssh/cistechhub-key.pem ec2-user@$(terraform output -raw public_ip)

# Watch setup progress
sudo tail -f /var/log/user-data.log

# Look for: "Cistechhub installation completed!"
```

#### Or use Systems Manager Session Manager (no SSH key needed)

```bash
# Get instance ID
terraform output instance_id

# Start session
aws ssm start-session --target $(terraform output -raw instance_id)

# Then watch logs
sudo tail -f /var/log/user-data.log
```

### 9. Verify Deployment

```bash
# Check if services are running
cd /opt/cistechhub
sudo docker-compose ps

# All services should show "Up"
```

Expected output:
```
NAME                      STATUS
cistechhub-auth           Up
cistechhub-mongodb        Up (healthy)
cistechhub-nginx          Up
cistechhub-web            Up
```

### 10. Access Application

```bash
# Get application URL
terraform output application_url

# Open in browser
open $(terraform output -raw application_url)
```

You should see the Cistechhub homepage!

### 11. Save Sensitive Credentials

```bash
# Save credentials to a secure file
terraform output mongodb_password > ~/cistechhub-secrets.txt
terraform output jwt_secret >> ~/cistechhub-secrets.txt

# Secure the file
chmod 600 ~/cistechhub-secrets.txt

# View credentials when needed
cat ~/cistechhub-secrets.txt
```

## Post-Deployment Tasks

### 1. Test Application Features

- [ ] Homepage loads correctly
- [ ] Authentication works (if configured)
- [ ] Course content is accessible
- [ ] MongoDB is accepting connections

### 2. Set Up Monitoring

```bash
# View CloudWatch logs in AWS Console
# Or use AWS CLI
aws logs tail /aws/ec2/cistechhub --follow

# Check application health
curl http://$(terraform output -raw public_ip)/health
```

### 3. Configure Backups (Optional)

```bash
# Set up automated backups using Ansible
cd ../../ansible

# Configure ansible.cfg with your key path
nano ansible.cfg

# Test connection
ansible all -m ping

# Set up cron job for daily backups
(crontab -l 2>/dev/null; echo "0 2 * * * cd /path/to/ansible && ansible-playbook playbooks/backup-mongodb.yml") | crontab -
```

### 4. Security Hardening

#### Update Security Group

```bash
# In terraform.tfvars, restrict SSH to your IP only
ssh_allowed_cidrs = ["YOUR.IP.ADDRESS/32"]

# Apply changes
terraform apply
```

#### Enable AWS CloudTrail (Optional)

```bash
# Enable CloudTrail for audit logging
aws cloudtrail create-trail \
  --name cistechhub-trail \
  --s3-bucket-name your-cloudtrail-bucket
```

#### Set Up AWS Budgets

1. Go to AWS Console > Billing > Budgets
2. Create a budget with $5 threshold
3. Set up email alerts

## Deployment Verification Checklist

- [ ] EC2 instance is running
- [ ] Elastic IP is associated
- [ ] All Docker containers are up
- [ ] Application is accessible via browser
- [ ] MongoDB is running and healthy
- [ ] Nginx is routing requests correctly
- [ ] CloudWatch logs are being collected
- [ ] Credentials are saved securely
- [ ] SSH access is restricted to your IP

## Common Deployment Issues

### Issue: "Error creating EC2 instance: VPCIdNotSpecified"

**Solution**: Ensure VPC is created first. This shouldn't happen with our modules, but if it does:
```bash
terraform destroy
terraform apply
```

### Issue: "Error: UnauthorizedOperation"

**Solution**: Check AWS credentials have sufficient permissions
```bash
aws sts get-caller-identity
# Verify you're using the correct account
```

### Issue: Application not accessible after 10 minutes

**Solution**: Check user-data script execution
```bash
ssh -i ~/.ssh/cistechhub-key.pem ec2-user@<PUBLIC_IP>
sudo cat /var/log/user-data.log
# Look for errors in the log
```

### Issue: "Error: InvalidKeyPair.NotFound"

**Solution**: Create the key pair or remove key_name from terraform.tfvars
```bash
aws ec2 create-key-pair --key-name cistechhub-key \
  --query 'KeyMaterial' --output text > ~/.ssh/cistechhub-key.pem
chmod 400 ~/.ssh/cistechhub-key.pem
```

### Issue: Connection timeout when accessing application

**Solution**: Check security group rules
```bash
# Verify security group allows port 80
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=dev-cistechhub-sg"

# Should show ingress rule for port 80 from 0.0.0.0/0
```

## Updating the Deployment

### Update Terraform Configuration

```bash
# Modify terraform.tfvars or module code
nano terraform.tfvars

# Preview changes
terraform plan

# Apply changes
terraform apply
```

### Update Application Code

```bash
# Using Ansible
cd ansible
ansible-playbook playbooks/update-application.yml

# Or manually via SSH
ssh -i ~/.ssh/cistechhub-key.pem ec2-user@<PUBLIC_IP>
cd /opt/cistechhub
sudo docker-compose pull
sudo docker-compose up -d --force-recreate
```

## Destroying the Deployment

When you're finished learning:

```bash
cd cloud-sandbox/environments/cistechhub

# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Type 'yes' when prompted
```

**Warning**: This will permanently delete:
- EC2 instance and all data
- EBS volumes
- S3 bucket contents (if not empty)
- Elastic IP
- VPC and networking resources

## Next Steps

1. **Set up a domain name** (optional)
   - Register domain in Route 53
   - Create hosted zone
   - Point domain to Elastic IP

2. **Add SSL/TLS certificate** (optional)
   - Request certificate in ACM
   - Deploy ALB module
   - Configure HTTPS

3. **Scale up** (after learning)
   - Upgrade to larger instance
   - Add MongoDB replica set
   - Add application load balancer
   - Enable auto-scaling

4. **Practice for AWS Solutions Architect exam**
   - Document your architecture
   - Create architecture diagrams
   - Explain design decisions
   - Practice cost optimization

## Support

If you encounter issues not covered here:

1. Check application logs: `sudo docker-compose logs`
2. Check CloudWatch Logs in AWS Console
3. Review Terraform state: `terraform show`
4. Verify AWS Free Tier usage in AWS Billing Dashboard

Good luck with your AWS migration and Solutions Architect exam preparation!
