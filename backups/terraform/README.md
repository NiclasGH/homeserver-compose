# Backup Storage in AWS

- The backup storage S3 bucket (`aws_s3_bucket.backup_storage`)
- A separate S3 bucket for Terraform remote state (created from `bootstrap/`)

## 1) Create service account and credentials for terraform

## 2) Create backend bucket

```bash
cd bootstrap
terraform init
terraform apply -var-file="bootstrap.tfvars"
```

## 3) Configure and use remote backend
From the project root, edit `backend.tf` and set:
- `bucket` to the backend bucket name from step 1

Then run:

```bash
terraform init
terraform apply -var-file="bucket.tfvars"
```

## 4) Authenticate to AWS
```bash
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
```

## Notes
- S3 bucket names must be globally unique.
