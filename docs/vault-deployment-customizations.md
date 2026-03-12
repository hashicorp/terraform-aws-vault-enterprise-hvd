# Deployment customizations

On this page are various deployment customizations and their corresponding input variables that you may set to meet your requirements.

## AWS Systems Manager (SSM) access

To enable secure instance access via AWS Systems Manager Session Manager (instead of SSH), set:

```hcl
ec2_allow_ssm = true
```

This attaches the `AmazonSSMManagedInstanceCore` IAM policy to the Vault instance role. The AMI must have the SSM agent installed ( Required for Redhat, while Amazon Linux 2023 and Ubuntu official AMIs include it by default ).

> **Note:** This is an alternative to SSH access and does not require opening port 22 or managing SSH keys.

## DNS

This module supports creating an _alias_ record in AWS Route53 for the Vault FQDN to resolve to the Vault API load balancer DNS name.


### Basic private hosted zone

For VPC-internal DNS resolution:

```hcl
create_route53_vault_dns_record      = true
route53_vault_hosted_zone_name       = "internal.example.com"
route53_vault_hosted_zone_is_private = true
```

> **Note:** Ensure `vault_fqdn` matches the desired DNS record name (e.g., `vault.example.com`).

## Custom AMI

If you have a custom AWS AMI you would like to use, you can specify it via the following module input variables:

```hcl
vm_image_id   = "<custom-ami-id>"
ec2_os_distro = "<matching-os-distro>"
```

### Supported OS distributions

| `ec2_os_distro` value | Description |
|----------------------|-------------|
| `ubuntu` | Ubuntu 22.04+ compatible |
| `rhel` | RHEL 9 compatible |
| `al2023` | Amazon Linux 2023 compatible |
| `centos` | CentOS (custom AMI required) |

### Important notes

- The `ec2_os_distro` value **must** match your custom AMI's operating system to ensure the correct package manager is used during installation.
- For CentOS, you **must** provide a custom AMI via `vm_image_id` as there is no default CentOS AMI data source.
- AMI IDs must start with `ami-`.

### Example: RHEL custom AMI

```hcl
vm_image_id   = "ami-0123456789abcdef0"
ec2_os_distro = "rhel"
```

## Binary verification

The install script performs GPG signature and SHA256 checksum verification on the Vault binary:

1. Downloads HashiCorp's GPG public key from `https://www.hashicorp.com/.well-known/pgp-key.txt`
1. Downloads the binary, SHA256SUMS, and signature files
1. Verifies the signature file is authentic
1. Validates the binary checksum

This ensures the Vault binary has not been tampered with during download.

> **Note:** On Amazon Linux 2023, the script automatically installs `gnupg2-full` (replacing `gnupg2-minimal`) to enable GPG verification.

## AWS Secrets Manager certificate formats

The module supports TLS certificates stored in AWS Secrets Manager in two formats:

### Plain PEM format
Store the certificate content directly as a string:
```
-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJAJC...
-----END CERTIFICATE-----
```

### Base64eEncoded format (recommended)
Store the certificate as a base64-encoded string. The install script automatically detects and decodes base64 content:
```
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0t...
```

### Validation

The install script validates certificates after retrieval by the checking the following.
1. Checks the file is not empty (exit code 6).
1. Verifies the content contains PEM header (`-----BEGIN `) (exit code 7).
1. Fails with clear error messages if validation fails.

### Troubleshooting certificate issues

If deployment fails with certificate errors, check `/var/log/vault-cloud-init.log` for:
- `Secret ARN cannot be empty` (exit code 5) - Secret ARN not provided.
- `Certificate file is empty or missing` (exit code 6) - Secret retrieval failed.
- `does not appear to contain PEM-formatted data` (exit code 7) - Content is not valid PEM format.

## Cross-zone load balancing

By default, each load balancer node distributes traffic only to registered targets in its availability zone. Cross-zone load balancing enables the load balancer to distribute traffic across all registered targets in all enabled availability zones.

### Configuration

```hcl
enable_cross_zone_load_balancing = true
```

### When to Enable

- **Multi-AZ deployments**: When Vault nodes are distributed across multiple AZs and you want even traffic distribution.
- **Uneven node distribution**: When the number of Vault nodes per AZ varies.
- **High availability**: Ensures traffic continues to all healthy nodes even if one AZ has fewer instances.

### Considerations

- Cross-zone load balancing may incur additional data transfer charges between AZs.
- For symmetric AZ deployments (equal nodes per AZ), cross-zone load balancing is optional.

## Load balancer security

The module creates a dedicated security group for the Network Load Balancer, separate from the Vault instance security group.

### Controlling load balancer access

To restrict which networks/services can access Vault via the load balancer, include the following in your configuration.

```hcl
# Allow specific CIDR blocks to access Vault via LB
net_ingress_lb_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]

# Allow specific security groups to access Vault via LB
net_ingress_lb_security_group_ids = ["sg-0123456789abcdef0"]
```

### Using the load balancer security group output

The module outputs the load balancer security group ID for use in downstream configurations per this output statement.

```hcl
output "vault_load_balancer_security_group_id" {
  value = module.vault.vault_load_balancer_security_group_id
}

## Security Group Configuration

### Controlling Vault Instance Access

The module supports both CIDR-based and Security Group ID-based ingress rules:

```hcl
# CIDR-based access to Vault API
net_ingress_vault_cidr_blocks = ["10.0.0.0/8"]

# Security group-based access to Vault API
net_ingress_vault_security_group_ids = ["sg-webapp", "sg-bastion"]

# CIDR-based SSH access
net_ingress_ssh_cidr_blocks = ["10.0.0.0/8"]

# Security group-based SSH access
net_ingress_ssh_security_group_ids = ["sg-bastion"]
```

### Notes

- CIDR rules are only created if the corresponding variable contains values.
- Security group ID rules use `for_each` for proper lifecycle management.
- Vault instances allow API traffic (port 8200) from each other for `auto_join` discovery.

## Deployment troubleshooting

In the `compute.tf`, there is a commented out local file resource that will render the Vault custom data script to a local file where this module is being run. This can be useful for reviewing the custom data script as it will be rendered on the deployed VM. This file will contain sensitive values, so do _not_ commit this and delete this file when done troubleshooting.

## Custom startup script

While this is not recommended, this module supports the ability to use your own custom startup script to install Vault.

### Configuration

```hcl
custom_startup_script_template = "my-custom-install.sh.tpl"
```

### Requirements

1. The script **must** exist in a folder named `./templates/` within your current working directory.
1. The script **must** contain all template variables used by the module (see default template for reference).
1. Use at your own risk - breaking changes to template variables may occur.

### Template variables

Your custom script must handle the following template variables.

| Variable | Description |
|----------|-------------|
| `${systemd_dir}` | Path to systemd unit files |
| `${vault_dir_config}` | Vault configuration directory |
| `${vault_dir_home}` | Vault home directory |
| `${vault_version}` | Vault version to install |
| `${vault_fqdn}` | Fully qualified domain name |
| ... | See `templates/install-vault.sh.tpl` for complete list |

### Debugging custom scripts

1. Enable the local file render in `compute.tf` (commented out) to preview rendered output.
1. Check `/var/log/vault-cloud-init.log` on deployed instances.

> **Note:** If using Amazon Linux 2023, your script should handle the `gnupg2-minimal` to `gnupg2-full` swap for GPG verification to work.
