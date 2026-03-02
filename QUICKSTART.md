# Quick Start Guide

This guide will help you deploy your first AWS infrastructure with Terraform in 10 minutes!

## Step 1: Install Prerequisites

### Install Terraform (if not already installed)

**macOS:**
```bash
brew install terraform
```

**Verify installation:**
```bash
terraform --version
```

### Install AWS CLI (if not already installed)

**macOS:**
```bash
brew install awscli
```

**Verify installation:**
```bash
aws --version
```

## Step 2: Configure AWS Credentials

If you don't have an AWS account:
1. Go to https://aws.amazon.com/free/
2. Create a free tier account

Once you have an account:
1. Log into AWS Console
2. Go to IAM → Users → Create User
3. Give it a name (e.g., "terraform-user")
4. Select "Attach policies directly"
5. Add these policies (for learning):
   - AdministratorAccess (WARNING: Only for learning! Use restrictive policies in production)
6. Create user
7. Go to Security Credentials → Create Access Key
8. Select "Command Line Interface (CLI)"
9. Save your Access Key ID and Secret Access Key

Configure AWS CLI:
```bash
aws configure
# AWS Access Key ID: <paste your key>
# AWS Secret Access Key: <paste your secret>
# Default region: us-east-1
# Default output format: json
```

## Step 3: Customize Your Configuration

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and change the bucket name to something unique:
```hcl
bucket_name = "my-unique-name-12345-learning-bucket"
```

## Step 4: Deploy Your Infrastructure

```bash
# Initialize Terraform (downloads providers)
terraform init

# See what will be created
terraform plan

# Deploy the infrastructure
terraform apply
```

Type `yes` when prompted.

This will create:
- ✅ VPC with public and private subnets
- ✅ Internet Gateway and NAT Gateway
- ✅ EC2 web server with Apache
- ✅ S3 bucket with encryption and versioning
- ✅ RDS MySQL database

**Wait time:** 5-10 minutes for everything to be created.

## Step 5: Test Your Infrastructure

After deployment completes, you'll see outputs:

```
Outputs:

web_server_url = "http://54.123.45.67"
s3_bucket_name = "my-unique-name-12345-learning-bucket-dev"
rds_endpoint = "dev-database.xxx.us-east-1.rds.amazonaws.com:3306"
```

**Test the web server:**
- Copy the `web_server_url` and paste it in your browser
- You should see a congratulations page!

**View your infrastructure:**
```bash
# List all created resources
terraform state list

# See detailed outputs
terraform output

# Get database password (it's auto-generated)
terraform output -json | jq -r '.db_password.value'
```

## Step 6: Explore and Learn

**View resources in AWS Console:**
1. Go to https://console.aws.amazon.com
2. Check out:
   - VPC Dashboard → Your VPCs
   - EC2 Dashboard → Instances
   - S3 → Buckets
   - RDS → Databases

**Modify and re-apply:**
```bash
# Make changes to any .tf file
# Then run:
terraform plan   # See what will change
terraform apply  # Apply the changes
```

## Step 7: Clean Up (IMPORTANT!)

**To avoid AWS charges, always destroy resources when done:**

```bash
terraform destroy
```

Type `yes` when prompted.

**Verify everything is deleted:**
- Check AWS Console
- Run: `terraform state list` (should be empty)

## Common Issues

### Issue: Bucket name already exists
**Solution:** S3 bucket names must be globally unique. Change the `bucket_name` in `terraform.tfvars` to something more unique.

### Issue: "No credentials found"
**Solution:** Run `aws configure` and enter your AWS access keys.

### Issue: Region not supported
**Solution:** Some AWS services aren't available in all regions. Use `us-east-1` or `us-west-2` for best compatibility.

### Issue: DB creation is slow
**Solution:** This is normal! RDS instances can take 5-10 minutes to create.

## Next Steps

### Beginner Level
1. **Modify the web server**: Edit `modules/compute/main.tf` user_data to change the webpage
2. **Add tags**: Add more tags to resources for organization
3. **Change instance size**: Update `instance_type` in variables

### Intermediate Level
1. **Add Application Load Balancer**: Create a new module for ALB
2. **Add Auto Scaling Group**: Replace single EC2 with ASG
3. **Add CloudWatch Alarms**: Monitor your resources
4. **Implement remote state**: Use S3 backend for state storage

### Advanced Level
1. **Multi-environment setup**: Create staging and production environments
2. **Add CI/CD**: Integrate with GitHub Actions
3. **Implement proper IAM**: Create least-privilege roles
4. **Add monitoring**: CloudWatch, logs, and metrics

## Learning Resources

**AWS Solutions Architect Exam:**
- Focus on: VPC design, EC2 instance types, S3 storage classes
- Understand: Multi-AZ vs Multi-Region, RDS read replicas
- Practice: Cost optimization, security best practices

**Terraform:**
- Read: https://developer.hashicorp.com/terraform/tutorials
- Practice: Modify existing modules, create new ones
- Learn: State management, workspaces, remote backends

**Cost Management:**
- Set up billing alerts in AWS Console
- Use AWS Cost Explorer
- Always `terraform destroy` when done learning!

## Questions?

- Terraform Docs: https://www.terraform.io/docs
- AWS Free Tier: https://aws.amazon.com/free/
- AWS Architecture: https://aws.amazon.com/architecture/

Happy Learning!
