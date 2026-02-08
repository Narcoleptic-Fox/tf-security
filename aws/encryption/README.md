# Encryption Module

KMS keys and encryption defaults for AWS.

## Planned Features

- [ ] Multi-region KMS key
- [ ] Key rotation policy
- [ ] S3 bucket key
- [ ] EBS default encryption
- [ ] RDS encryption key
- [ ] Secrets Manager key
- [ ] Key policies with least privilege

## Usage (Coming Soon)

```hcl
module "encryption" {
  source = "github.com/Narcoleptic-Fox/tf-security//aws/encryption"

  naming_prefix = module.naming.prefix
  tags          = module.tags.common_tags
}

# Use the key
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.encryption.s3_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}
```
