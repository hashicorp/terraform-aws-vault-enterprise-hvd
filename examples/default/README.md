# Default Example

This example deploys Vault Enterprise aligned with HashiCorp Validated Design. This is the minimum configuration required to standup a highly-available Vault Enterprise cluster with:

* 3 redundancy zones each with one voter and one non-voter node
* Auto-unseal with the AWS KMS seal type
* Cloud auto-join for peer discovery
* Publicly-available load balanced Vault API endpoint
* End-to-end TLS

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ cp terraform.tfvars.example terraform.tfvars
# Update variable values
$ terraform plan
$ terraform apply
```

## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_default_example"></a> [default\_example](#module\_default\_example) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_load_balancing_scheme"></a> [load\_balancing\_scheme](#input\_load\_balancing\_scheme) | Type of load balancer to use (INTERNAL, EXTERNAL, or NONE) | `string` | `"INTERNAL"` | no |
| <a name="input_net_ingress_ssh_cidr_blocks"></a> [net\_ingress\_ssh\_cidr\_blocks](#input\_net\_ingress\_ssh\_cidr\_blocks) | List of CIDR blocks to allow SSH access to Vault instances. | `list(string)` | `[]` | no |
| <a name="input_net_ingress_vault_cidr_blocks"></a> [net\_ingress\_vault\_cidr\_blocks](#input\_net\_ingress\_vault\_cidr\_blocks) | List of CIDR blocks to allow API access to Vault. | `list(string)` | `[]` | no |
| <a name="input_net_lb_subnet_ids"></a> [net\_lb\_subnet\_ids](#input\_net\_lb\_subnet\_ids) | The subnet IDs in the VPC to host the load balancer in. | `list(string)` | n/a | yes |
| <a name="input_net_vault_subnet_ids"></a> [net\_vault\_subnet\_ids](#input\_net\_vault\_subnet\_ids) | (required) The subnet IDs in the VPC to host the Vault servers in | `list(string)` | n/a | yes |
| <a name="input_net_vpc_id"></a> [net\_vpc\_id](#input\_net\_vpc\_id) | (required) The VPC ID to host the cluster in | `string` | n/a | yes |
| <a name="input_friendly_name_prefix"></a> [resource\_name\_prefix](#input\_resource\_name\_prefix) | Name prefix to use when naming cloud resources | `string` | `"vault"` | no |
| <a name="input_sm_vault_license_arn"></a> [sm\_vault\_license\_arn](#input\_sm\_vault\_license\_arn) | The ARN of the license secret in AWS Secrets Manager | `string` | n/a | yes |
| <a name="input_sm_vault_tls_ca_bundle"></a> [sm\_vault\_tls\_ca\_bundle](#input\_sm\_vault\_tls\_ca\_bundle) | (required) The ARN of the CA bundle secret in AWS Secrets Manager | `string` | n/a | yes |
| <a name="input_sm_vault_tls_cert_arn"></a> [sm\_vault\_tls\_cert\_arn](#input\_sm\_vault\_tls\_cert\_arn) | (required) The ARN of the signed TLS certificate secret in AWS Secrets Manager | `string` | n/a | yes |
| <a name="input_sm_vault_tls_cert_key_arn"></a> [sm\_vault\_tls\_cert\_key\_arn](#input\_sm\_vault\_tls\_cert\_key\_arn) | (required) The ARN of the signed TLS certificate's private key secret in AWS Secrets Manager | `string` | n/a | yes |
| <a name="input_vault_fqdn"></a> [vault\_fqdn](#input\_vault\_fqdn) | Fully qualified domain name to use for joining peer nodes and optionally DNS | `string` | n/a | yes |
| <a name="input_vault_seal_awskms_key_arn"></a> [vault\_seal\_awskms\_key\_arn](#input\_vault\_seal\_awskms\_key\_arn) | The KMS key ID to use for Vault auto-unseal | `string` | n/a | yes |
| <a name="input_vm_key_pair_name"></a> [vm\_key\_pair\_name](#input\_vm\_key\_pair\_name) | The machine SSH key pair name to use for the cluster nodes | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_load_balancer_name"></a> [load\_balancer\_name](#output\_load\_balancer\_name) | n/a |
| <a name="output_vault_cli_config"></a> [vault\_cli\_config](#output\_vault\_cli\_config) | n/a |
