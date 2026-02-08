# Open Policy Agent Rules

Policy-as-code rules for Terraform plan validation.

## Planned

- [ ] Required tag policies
- [ ] Public access restrictions
- [ ] Encryption requirements
- [ ] Naming convention enforcement

## Usage

```bash
# Validate terraform plan
opa eval --data policies/opa --input tfplan.json "data.terraform.deny"
```
