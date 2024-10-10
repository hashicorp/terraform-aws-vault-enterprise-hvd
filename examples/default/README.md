# Default example

This example deploys Vault Enterprise aligned with HashiCorp Validated Design. This is the minimum configuration required to standup a highly-available Vault Enterprise cluster with:

- 3 redundancy zones each with one voter and one non-voter node
- Auto-unseal with the AWS KMS seal type
- Cloud auto-join for peer discovery
- Publicly-available load balanced Vault API endpoint
- End-to-end TLS

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ cp terraform.tfvars.example terraform.tfvars
# Update variable values
$ terraform plan
$ terraform apply
```
