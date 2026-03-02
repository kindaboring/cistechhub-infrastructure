# Ansible Playbooks for Cistechhub

This directory contains Ansible playbooks for managing the Cistechhub application on AWS.

## Prerequisites

```bash
# Install Ansible
pip install ansible boto3 botocore

# Install AWS collection
ansible-galaxy collection install amazon.aws

# Configure AWS credentials
aws configure
```

## Configuration

### Update ansible.cfg

Edit `ansible.cfg` and set your SSH key path:

```ini
private_key_file = ~/.ssh/cistechhub-key.pem
```

### Test Connection

```bash
# Test dynamic inventory
ansible-inventory -i inventory/aws_ec2.yml --list

# Ping servers
ansible all -m ping
```

## Available Playbooks

### 1. Deploy Application

Deploys or redeploys the Cistechhub application.

```bash
ansible-playbook playbooks/deploy-cistechhub.yml
```

**What it does:**
- Verifies Docker and Docker Compose are installed
- Pulls latest Docker images
- Restarts all services
- Waits for services to be healthy
- Displays service status and logs

### 2. Update Application

Updates the application to the latest Docker images.

```bash
ansible-playbook playbooks/update-application.yml
```

**What it does:**
- Pulls latest images
- Recreates containers with new images
- Performs rolling update (one server at a time)
- Verifies application health
- Zero-downtime deployment

### 3. Backup MongoDB

Creates a backup of the MongoDB database.

```bash
ansible-playbook playbooks/backup-mongodb.yml
```

**What it does:**
- Creates backup directory
- Performs mongodump
- Copies backup to host
- Removes backups older than 7 days
- Stores backup at `/backup/mongodb/`

**Restore from backup:**
```bash
ssh -i ~/.ssh/cistechhub-key.pem ec2-user@<PUBLIC_IP>
cd /opt/cistechhub
sudo docker cp /backup/mongodb/backup-YYYY-MM-DD.archive cistechhub-mongodb:/tmp/
sudo docker-compose exec mongodb mongorestore --archive=/tmp/backup-YYYY-MM-DD.archive --gzip
```

### 4. Monitoring and Health Check

Checks the health of the application and displays metrics.

```bash
ansible-playbook playbooks/monitoring.yml
```

**What it does:**
- Checks Docker service status
- Displays container status
- Shows disk and memory usage
- Displays Docker container stats
- Checks for recent errors
- Tests application endpoint

## Usage Examples

### Deploy to all servers

```bash
ansible-playbook playbooks/deploy-cistechhub.yml
```

### Deploy to specific environment

```bash
ansible-playbook playbooks/deploy-cistechhub.yml -l env_dev
```

### Verbose output

```bash
ansible-playbook playbooks/deploy-cistechhub.yml -v
```

### Check mode (dry run)

```bash
ansible-playbook playbooks/deploy-cistechhub.yml --check
```

### Run specific tasks

```bash
ansible-playbook playbooks/deploy-cistechhub.yml --tags "restart"
```

## Scheduled Automation

### Daily Backups

Add to crontab:

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /path/to/ansible && ansible-playbook playbooks/backup-mongodb.yml >> /var/log/cistechhub-backup.log 2>&1
```

### Hourly Health Checks

```bash
# Add hourly health check
0 * * * * cd /path/to/ansible && ansible-playbook playbooks/monitoring.yml >> /var/log/cistechhub-health.log 2>&1
```

### Weekly Updates

```bash
# Update every Sunday at 3 AM
0 3 * * 0 cd /path/to/ansible && ansible-playbook playbooks/update-application.yml >> /var/log/cistechhub-update.log 2>&1
```

## Troubleshooting

### Dynamic inventory not working

```bash
# Check AWS credentials
aws sts get-caller-identity

# Test inventory manually
ansible-inventory -i inventory/aws_ec2.yml --graph

# Check boto3 is installed
python3 -c "import boto3; print(boto3.__version__)"
```

### SSH connection failed

```bash
# Verify key permissions
chmod 400 ~/.ssh/cistechhub-key.pem

# Test SSH manually
ssh -i ~/.ssh/cistechhub-key.pem ec2-user@<PUBLIC_IP>

# Check security group allows SSH
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=dev-cistechhub-sg"
```

### Playbook fails to find hosts

```bash
# List all discovered hosts
ansible-inventory -i inventory/aws_ec2.yml --list

# Verify instance tags
aws ec2 describe-instances --filters "Name=tag:Project,Values=cistechhub"

# Check instance is running
aws ec2 describe-instance-status --instance-ids <INSTANCE_ID>
```

## Best Practices

1. **Always test with --check first**
   ```bash
   ansible-playbook playbooks/deploy-cistechhub.yml --check
   ```

2. **Use version control for playbooks**
   - Commit changes before running
   - Tag releases

3. **Run backups before updates**
   ```bash
   ansible-playbook playbooks/backup-mongodb.yml
   ansible-playbook playbooks/update-application.yml
   ```

4. **Monitor logs during deployment**
   ```bash
   ansible-playbook playbooks/deploy-cistechhub.yml -v
   ```

5. **Set up notifications** (advanced)
   - Slack notifications on failures
   - Email alerts for critical issues

## Advanced Usage

### Creating Custom Playbooks

Example: Restart only nginx

```yaml
---
- name: Restart Nginx Only
  hosts: tag_Project_cistechhub
  become: true
  vars:
    app_dir: /opt/cistechhub

  tasks:
    - name: Restart nginx container
      shell: |
        cd {{ app_dir }}
        docker-compose restart nginx
```

### Using Ansible Vault for Secrets

```bash
# Create encrypted file
ansible-vault create secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Use in playbook
ansible-playbook playbooks/deploy-cistechhub.yml --ask-vault-pass
```

## Integration with CI/CD

### GitLab CI Example

```yaml
deploy:
  stage: deploy
  script:
    - pip install ansible boto3
    - ansible-galaxy collection install amazon.aws
    - ansible-playbook playbooks/deploy-cistechhub.yml
  only:
    - main
```

### GitHub Actions Example

```yaml
name: Deploy to AWS
on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Ansible
        run: pip install ansible boto3
      - name: Deploy
        run: |
          cd ansible
          ansible-playbook playbooks/deploy-cistechhub.yml
```

## Support

For issues with Ansible playbooks:
1. Check verbose output: `-vvv`
2. Verify AWS credentials
3. Check instance is reachable
4. Review playbook logs
