# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this repository, please open a [GitHub issue](https://github.com/kindaboring/cistechhub-infrastructure/issues) or contact the maintainer directly. Do not include sensitive details in public issue titles.

## Security Posture

### No Long-Lived AWS Credentials

GitHub Actions authenticates to AWS via **OpenID Connect (OIDC)**. No `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` are stored as secrets. GitHub Actions requests a short-lived token at runtime and assumes an IAM role scoped to this repository only.

### No SSH Keys

The EC2 instance is managed exclusively via **AWS Systems Manager Session Manager**. Port 22 does not need to be open. Ansible connects using the `community.aws.aws_ssm` connection plugin. No private keys are stored in GitHub secrets, and access survives an instance recreation without any secret rotation.

### Secrets Management

- MongoDB passwords and JWT secrets are generated at provision time using Terraform's `random_password` resource and marked `sensitive = true`
- Secrets are injected into the EC2 instance via user-data at launch and are never stored in the repository or in Terraform state in plain text
- Google OAuth credentials are passed to Terraform at plan/apply time via GitHub Actions secrets — never committed to the repo

### Encryption at Rest

- EBS root volume is encrypted with AES-256 (`encrypted = true` on the `aws_instance` resource)
- S3 uploads bucket uses server-side encryption (`SSE-S3 / AES-256`)
- S3 public access is fully blocked (`block_public_acls`, `block_public_policy`, `restrict_public_buckets`)

### IaC Security Scanning

Every pull request and weekly on a schedule:

- **tfsec** — scans Terraform for misconfigurations
- **Checkov** — policy-as-code checks against CIS benchmarks

Findings are uploaded to the **GitHub Security tab** as SARIF reports. HIGH and CRITICAL findings are reviewed before any merge.

### Supply Chain Security

All GitHub Actions are pinned to **immutable commit SHAs** rather than mutable version tags (e.g. `@v4`). This prevents a compromised upstream tag from silently altering workflow behaviour.

### Manual Approval Gates

`terraform apply` and Ansible deployments are gated behind a GitHub Environment (`production`) with required reviewers. Infrastructure changes never reach AWS without a human sign-off.

### IAM Least Privilege

The EC2 instance role is scoped to only the permissions it needs at runtime:

- `AmazonSSMManagedInstanceCore` — Session Manager access
- `CloudWatchAgentServerPolicy` — log shipping
- Inline S3 policy scoped to the single uploads bucket (`s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`, `s3:ListBucket`)
