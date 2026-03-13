## v0.3.1

## What's Changed
* Rel 0.3.0 by @abuxton in https://github.com/hashicorp/terraform-aws-vault-enterprise-hvd/pull/47
* feat: add vault cluster TCP 8201 listener by @abuxton in https://github.com/hashicorp/terraform-aws-vault-enterprise-hvd/pull/46


**Full Changelog**: https://github.com/hashicorp/terraform-aws-vault-enterprise-hvd/compare/0.3.0...0.3.1

# Changelog

## v0.3.0

### Added

- Multi-OS distribution support (Ubuntu, RHEL, Amazon Linux 2023, CentOS)
- Custom AMI support with validation for `vm_image_id` parameter
- Route53 DNS integration with new variables `create_route53_vault_dns_record`, `route53_vault_hosted_zone_name`, `route53_vault_hosted_zone_is_private`
- AWS Systems Manager (SSM) support with `ec2_allow_ssm` variable for secure instance access
- Custom startup script template support via `custom_startup_script_template` variable
- Automatic system architecture detection (linux_amd64, linux_arm64, linux_arm)
- Binary checksum verification with GPG signature and SHA256 validation
- Cross-zone load balancing support with `enable_cross_zone_load_balancing` variable
- Base64-encoded secrets manager support with auto-detection and PEM validation
- Dedicated load balancer security group with new variables `net_ingress_lb_cidr_blocks`, `net_ingress_lb_security_group_ids`
- AWS partition data source for proper ARN construction across partitions (commercial, GovCloud, China)
- Enhanced logging and error handling in install scripts with improved exit codes (5-7) for certificate issues
- Security group rule improvements using `for_each` for `net_ingress_vault_security_group_ids` and `net_ingress_ssh_security_group_ids`

### Changed

- Raft performance multiplier default changed from `0` to `5` to prevent HeartbeatTimeout errors
- AWS provider version constraint updated to support `>= 5.0` (including 6.x with deprecation warnings)
- User data script compression changed from `base64encode` to `base64gzip` for reduced payload size
- AMI selection refactored with conditional data sources based on `ec2_os_distro`
- Install script enhanced with improved certificate handling and package management
- Uses `var.vault_port_api` instead of hardcoded port values in install script and security group rules
- Added self-referencing security group rule for Vault API port (8200) to support `auto_join`

### Fixed

- AWS partition ARN validation with wildcard support (adds missing fix from bugfix/aws-partition-arn-validation)
- Invalid variable references within user data script template
- Vault telemetry configuration
- EBS volume attachment reliability with 20-second delay
- Error handling when no EBS volume is found attached

### Removed

- Hardcoded port references in favor of `var.vault_port_api`
- Commented-out code in `locals.tf`

## v0.2.0

### Added

- Telemetry configuration support
- Improved workflow automation (JIRA sync)
- Enhanced documentation and support text in README

### Changed

- User data template improvements

### Fixed

- Redundant redirection in user data template
- Invalid variable reference within user data script template
- Vault TLS CA bundle configuration

## v0.1.0

### Added

- Initial Terraform module for HashiCorp Vault Enterprise on AWS
- Compute infrastructure (EC2) configuration
- IAM roles and policies for Vault instances
- Network Load Balancer setup
- KMS encryption key management
- RDS Aurora database backend support
- Route53 DNS record management
- S3 bucket configuration for Vault storage
- Network security groups configuration
- Comprehensive variable definitions and outputs
- Documentation and examples

### Changed

- Architecture diagram and README documentation improvements

### Fixed

- README title and introduction formatting
- Cluster architecture diagram image source
