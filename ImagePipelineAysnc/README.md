# AWS Image Conversion Pipeline

Converts JPEG images to **WebP**, **PNG**, and **AVIF** automatically using
S3 → Lambda → S3, with metadata stored in DynamoDB. All infrastructure is
managed by Terraform.

## Architecture

```
Upload JPEG → S3 input bucket (jpeg/ prefix)
                    ↓  S3 event trigger
              Lambda (Python + Pillow)
              ├── Converts to WebP, PNG, AVIF, JPEG copy
              ├── Stores all formats → S3 output bucket
              │     /jpeg/  /png/  /webp/  /avif/
              └── Writes metadata → DynamoDB
```

## Prerequisites

| Tool        | Version  | Install                              |
|-------------|----------|--------------------------------------|
| Terraform   | >= 1.6   | https://developer.hashicorp.com/terraform/install |
| AWS CLI     | >= 2.x   | https://aws.amazon.com/cli/          |
| Python/pip  | >= 3.12  | For building the Lambda layer locally |

AWS credentials must be configured (`aws configure` or env vars).

## Quick Start

### 1. Configure your project name

Edit `terraform.tfvars`:

```hcl
project_name = "yourname"   # lowercase, no spaces
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Preview what will be created

```bash
terraform plan
```

### 4. Deploy

```bash
terraform apply
```

Type `yes` when prompted. Terraform will print the bucket names when done.

### 5. Test it

```bash
# Upload a JPEG
aws s3 cp my-photo.jpg s3://<input-bucket>/jpeg/my-photo.jpg

# Wait ~5 seconds, then list converted outputs
aws s3 ls s3://<output-bucket>/ --recursive

# Check DynamoDB metadata
aws dynamodb scan --table-name <table-name>
```

## File Structure

```
image-pipeline/
├── main.tf              Root — wires all modules
├── variables.tf         Input variables
├── outputs.tf           Post-deploy info
├── terraform.tfvars     Your values (edit this)
├── modules/
│   ├── s3/              Input + output buckets, S3 trigger
│   ├── lambda/          Function, layer, CloudWatch logs
│   ├── dynamodb/        Metadata table
│   └── iam/             Execution role + policies
└── lambda_src/
    ├── handler.py       Python conversion code (Pillow)
    └── requirements.txt Pillow + pillow-avif-plugin
```

## DynamoDB Metadata Schema

| Field                | Type   | Description                       |
|----------------------|--------|-----------------------------------|
| `image_id` (PK)      | String | UUID generated per image          |
| `original_filename`  | String | Original uploaded filename (GSI)  |
| `original_key`       | String | S3 key of the source file         |
| `source_bucket`      | String | Input bucket name                 |
| `output_bucket`      | String | Output bucket name                |
| `original_size_bytes`| Number | Size of the original JPEG         |
| `image_width`        | Number | Pixel width                       |
| `image_height`       | Number | Pixel height                      |
| `formats_created`    | List   | e.g. ["jpeg","png","webp","avif"] |
| `s3_keys`            | Map    | S3 key for each format            |
| `processed_at`       | String | ISO 8601 UTC timestamp            |
| `status`             | String | "success" or "error"              |

## Tear down

```bash
terraform destroy
```

> Note: `force_destroy = true` is set on both S3 buckets so Terraform can
> delete them even if they contain objects. Remove that flag in production.
