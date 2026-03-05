# AWS Cloud Sandbox

Production-grade AWS infrastructure for the [Cistechhub](https://github.com/kindaboring/cistechhub) web application, built to demonstrate end-to-end DevOps and cloud engineering practices. The infrastructure is fully automated — from provisioning to deployment — using Terraform, Ansible, and GitHub Actions.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        GitHub Actions                       │
│                                                             │
│  [App Repo] ──repository_dispatch──► [Infra Repo]          │
│       │                                    │                │
│  Build & push                    Validate → Plan → Apply   │
│  Docker image                    (manual approval gate)     │
└────────────────────────────────────┬────────────────────────┘
                                     │ terraform apply
                              ┌──────▼──────┐
                              │     AWS     │
                              │             │
                              │  VPC        │
                              │  ├─ Public Subnet ──► EC2 (t2.micro)
                              │  │                     ├─ nginx
                              │  │                     ├─ Node.js auth API
                              │  │                     ├─ Next.js frontend
                              │  │                     └─ MongoDB
                              │  └─ Private Subnet (reserved)
                              │                        │
                              │  Elastic IP ───────────┘
                              │  S3 (file uploads)
                              │  IAM Role + SSM
                              └─────────────────
```

## Tech Stack

| Layer | Technology |
|---|---|
| Infrastructure as Code | Terraform >= 1.9, AWS Provider ~> 5.0 |
| Configuration Management | Ansible, `amazon.aws` collection |
| CI/CD | GitHub Actions |
| Security Scanning | tfsec, Checkov (SARIF → GitHub Security tab) |
| Runtime | Docker, Docker Compose, Amazon Linux 2 |
| Cloud | AWS (EC2, VPC, S3, IAM, EIP, SSM) |

## Repository Structure

```
cloud-sandbox/
├── .github/workflows/
│   ├── terraform.yml            # Validate → Plan → Apply pipeline
│   ├── ansible-lint.yml         # Playbook linting and syntax checks
│   ├── security-scan.yml        # tfsec + Checkov on every PR
│   └── deploy-on-image-push.yml # Cross-repo deploy trigger
│
├── environments/
│   └── cistechhub/              # Live environment config
│       ├── main.tf              # Module composition
│       ├── variables.tf
│       └── terraform.tfvars.example
│
└── modules/
    ├── networking/              # VPC, subnets, IGW, route tables
    ├── cistechhub-free-tier/    # EC2, security group, IAM, EIP, user-data
    ├── cistechhub-storage/      # S3 bucket with CORS
    ├── alb/                     # Application Load Balancer
    ├── database/                # RDS (reserved for scaling)
    ├── mongodb/                 # Self-hosted MongoDB on EC2
    ├── ecr/                     # Elastic Container Registry
    └── secrets/                 # AWS Secrets Manager
```

## CI/CD Pipeline

### Terraform Workflow (`terraform.yml`)

Triggered on every push and pull request that touches `environments/` or `modules/`.

```
PR opened                        Merge to main
    │                                 │
    ▼                                 ▼
Validate                          Validate
(fmt check, terraform validate)       │
    │                             Plan (requires AWS creds)
    ▼                                 │
Plan                              ┌───▼──────────────────┐
(posts full diff as PR comment)   │  Manual approval gate │
                                  │  (production env)     │
                                  └───┬──────────────────┘
                                      │
                                    Apply
```

### Cross-Repository Deployment (`deploy-on-image-push.yml`)

When the [application repository](https://github.com/kindaboring/cistechhub) builds and pushes a new Docker image, it fires a `repository_dispatch` event here. This triggers a rolling deploy via Ansible — no SSH keys required.

```
App repo: image push to ECR
         │
         └─► repository_dispatch (container-image-updated)
                      │
                      ▼
             Manual approval gate
                      │
                      ▼
             Ansible rolling deploy
             (docker-compose pull + force-recreate)
                      │
                      ▼
             Health check at /health
```

### Security Scanning (`security-scan.yml`)

Runs tfsec and Checkov on every PR and on a weekly schedule. Findings are uploaded to the GitHub Security tab as SARIF reports.

## Key Design Decisions

**SSM over SSH** — The EC2 instance has `AmazonSSMManagedInstanceCore` attached. All Ansible automation runs via the `community.aws.aws_ssm` connection plugin. No private keys are stored in GitHub secrets, port 22 does not need to be open, and access survives an instance recreation without any secret rotation.

**Manual approval gates** — The `terraform apply` and deployment jobs are gated behind a GitHub Environment (`production`) with required reviewers. Infrastructure changes never reach AWS without a human sign-off.

**Modular Terraform** — Each concern (networking, compute, storage, secrets) is an independent module. The `environments/cistechhub/` directory composes them, making it straightforward to add environments (staging, prod) by adding a new directory.

**Secrets never in state plain text** — MongoDB passwords and JWT secrets are generated by Terraform's `random_password` resource and marked `sensitive = true`. They are injected into the EC2 instance via user-data at launch time and never stored in the repo.

## Deploying

1. Copy `environments/cistechhub/terraform.tfvars.example` to `terraform.tfvars` and fill in your values.

2. Configure the required GitHub Actions secrets (see below).

3. Open a pull request — the pipeline will run `terraform plan` and post the diff as a comment.

4. Merge to `main` and approve the deployment in the GitHub Actions UI.

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID (optional) |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret (optional) |
| `GOOGLE_REDIRECT_URI` | Google OAuth redirect URI (optional) |

### Required GitHub Environments

Create two environments under **Settings → Environments**:

- `plan` — no restrictions
- `production` — add yourself as a required reviewer

## Local Usage

```bash
cd environments/cistechhub

# Initialize
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply

# Tear down
terraform destroy
```

```bash
cd ansible

# Health check
ansible-playbook playbooks/monitoring.yml -i inventory/aws_ec2.yml

# Rolling deploy
ansible-playbook playbooks/update-application.yml -i inventory/aws_ec2.yml

# Backup MongoDB
ansible-playbook playbooks/backup-mongodb.yml -i inventory/aws_ec2.yml
```
