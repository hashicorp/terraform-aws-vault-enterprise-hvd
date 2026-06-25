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
# Update region in providers.tf
$ terraform plan
$ terraform apply
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_default_example"></a> [default\_example](#module\_default\_example) | ../.. | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_net_lb_subnet_ids"></a> [net\_lb\_subnet\_ids](#input\_net\_lb\_subnet\_ids) | The subnet IDs in the VPC to host the load balancer in. | `list(string)` | n/a | yes |
| <a name="input_net_vault_subnet_ids"></a> [net\_vault\_subnet\_ids](#input\_net\_vault\_subnet\_ids) | (required) The subnet IDs in the VPC to host the Vault servers in | `list(string)` | n/a | yes |
| <a name="input_net_vpc_id"></a> [net\_vpc\_id](#input\_net\_vpc\_id) | (required) The VPC ID to host the cluster in | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to deploy resources in. | `string` | n/a | yes |
| <a name="input_sm_vault_license_arn"></a> [sm\_vault\_license\_arn](#input\_sm\_vault\_license\_arn) | The ARN of the license secret in AWS Secrets Manager | `string` | n/a | yes |
| <a name="input_sm_vault_tls_ca_bundle"></a> [sm\_vault\_tls\_ca\_bundle](#input\_sm\_vault\_tls\_ca\_bundle) | (required) The ARN of the CA bundle secret in AWS Secrets Manager, Secret should be stored as a base64-encoded string. Secret type should be plaintext. | `string` | n/a | yes |
| <a name="input_sm_vault_tls_cert_arn"></a> [sm\_vault\_tls\_cert\_arn](#input\_sm\_vault\_tls\_cert\_arn) | (required) The ARN of the signed TLS certificate secret in AWS Secrets Manager, Secret should be stored as a base64-encoded string. Secret type should be plaintext. | `string` | n/a | yes |
| <a name="input_sm_vault_tls_cert_key_arn"></a> [sm\_vault\_tls\_cert\_key\_arn](#input\_sm\_vault\_tls\_cert\_key\_arn) | (required) The ARN of the signed TLS certificate's private key secret in AWS Secrets Manager, Secret should be stored as a base64-encoded string. Secret type should be plaintext. | `string` | n/a | yes |
| <a name="input_vault_fqdn"></a> [vault\_fqdn](#input\_vault\_fqdn) | Fully qualified domain name to use for joining peer nodes and optionally DNS | `string` | n/a | yes |
| <a name="input_vault_seal_awskms_key_arn"></a> [vault\_seal\_awskms\_key\_arn](#input\_vault\_seal\_awskms\_key\_arn) | The KMS key ID to use for Vault auto-unseal | `string` | n/a | yes |
| <a name="input_additional_package_names"></a> [additional\_package\_names](#input\_additional\_package\_names) | List of additional repository package names to install | `set(string)` | `[]` | no |
| <a name="input_asg_health_check_grace_period"></a> [asg\_health\_check\_grace\_period](#input\_asg\_health\_check\_grace\_period) | The amount of time to expire before the autoscaling group terminates an unhealthy node is terminated | `string` | `600` | no |
| <a name="input_asg_health_check_type"></a> [asg\_health\_check\_type](#input\_asg\_health\_check\_type) | Defines how autoscaling health checking is done | `string` | `"EC2"` | no |
| <a name="input_asg_node_count"></a> [asg\_node\_count](#input\_asg\_node\_count) | The number of nodes to create in the pool. | `number` | `6` | no |
| <a name="input_create_route53_vault_dns_record"></a> [create\_route53\_vault\_dns\_record](#input\_create\_route53\_vault\_dns\_record) | Boolean to create Route53 Alias Record for `vault_hostname` resolving to Load Balancer DNS name. If `true`, `route53_vault_hosted_zone_name` is also required. | `bool` | `false` | no |
| <a name="input_custom_startup_script_template"></a> [custom\_startup\_script\_template](#input\_custom\_startup\_script\_template) | Filename of a custom Vault Install script template to use in place of the built-in user\_data script. The file must exist within a directory named './templates' in your current working directory. | `string` | `null` | no |
| <a name="input_ec2_allow_ssm"></a> [ec2\_allow\_ssm](#input\_ec2\_allow\_ssm) | Boolean to attach the `AmazonSSMManagedInstanceCore` policy to the Vault instance role (`aws_iam_role.vault_iam_role`), allowing the SSM agent (if present) to function. | `bool` | `false` | no |
| <a name="input_ec2_os_distro"></a> [ec2\_os\_distro](#input\_ec2\_os\_distro) | Linux OS distribution type for EC2 instance. Choose from `al2023`, `ubuntu`, `rhel`, `centos`. | `string` | `"ubuntu"` | no |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable\_cross\_zone\_load\_balancing](#input\_enable\_cross\_zone\_load\_balancing) | Enable cross-zone load balancing for the Network Load Balancer. | `bool` | `false` | no |
| <a name="input_enable_vault_cluster_port_listener"></a> [enable\_vault\_cluster\_port\_listener](#input\_enable\_vault\_cluster\_port\_listener) | Enable Network Load Balancer listener on port 8201 (Vault cluster port). When enabled, creates an additional listener and target group for the cluster port. | `bool` | `false` | no |
| <a name="input_friendly_name_prefix"></a> [friendly\_name\_prefix](#input\_friendly\_name\_prefix) | Name prefix to use when naming cloud resources | `string` | `"vault"` | no |
| <a name="input_health_check_deregistration_delay"></a> [health\_check\_deregistration\_delay](#input\_health\_check\_deregistration\_delay) | Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. | `number` | `15` | no |
| <a name="input_health_check_interval"></a> [health\_check\_interval](#input\_health\_check\_interval) | Approximate amount of time, in seconds, between health checks of an individual target. The range is 5-300. | `number` | `5` | no |
| <a name="input_health_check_timeout"></a> [health\_check\_timeout](#input\_health\_check\_timeout) | Amount of time, in seconds, during which no response from a target means a failed health check. The range is 2–120 seconds. | `number` | `3` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | Path for IAM entities | `string` | `"/"` | no |
| <a name="input_iam_role_permissions_boundary_arn"></a> [iam\_role\_permissions\_boundary\_arn](#input\_iam\_role\_permissions\_boundary\_arn) | The ARN of the policy that is used to set the permissions boundary for the role | `string` | `null` | no |
| <a name="input_load_balancing_scheme"></a> [load\_balancing\_scheme](#input\_load\_balancing\_scheme) | Type of load balancer to use (INTERNAL, EXTERNAL, or NONE) | `string` | `"INTERNAL"` | no |
| <a name="input_net_ingress_lb_cidr_blocks"></a> [net\_ingress\_lb\_cidr\_blocks](#input\_net\_ingress\_lb\_cidr\_blocks) | List of CIDR blocks to allow API access to Vault via Load Balancer. | `list(string)` | `[]` | no |
| <a name="input_net_ingress_lb_cluster_cidr_blocks"></a> [net\_ingress\_lb\_cluster\_cidr\_blocks](#input\_net\_ingress\_lb\_cluster\_cidr\_blocks) | List of CIDR blocks to allow cluster port (8201) access to Vault via Load Balancer. Only used when enable\_vault\_cluster\_port\_listener is true. Required when the cluster port listener is enabled. | `list(string)` | `null` | no |
| <a name="input_net_ingress_lb_security_group_ids"></a> [net\_ingress\_lb\_security\_group\_ids](#input\_net\_ingress\_lb\_security\_group\_ids) | List of security group IDs to allow API access to Vault via Load Balancer. | `list(string)` | `[]` | no |
| <a name="input_net_ingress_ssh_cidr_blocks"></a> [net\_ingress\_ssh\_cidr\_blocks](#input\_net\_ingress\_ssh\_cidr\_blocks) | List of CIDR blocks to allow SSH access to Vault instances. | `list(string)` | `[]` | no |
| <a name="input_net_ingress_ssh_security_group_ids"></a> [net\_ingress\_ssh\_security\_group\_ids](#input\_net\_ingress\_ssh\_security\_group\_ids) | List of security group IDs to allow SSH access to Vault instances. | `list(string)` | `[]` | no |
| <a name="input_net_ingress_vault_cidr_blocks"></a> [net\_ingress\_vault\_cidr\_blocks](#input\_net\_ingress\_vault\_cidr\_blocks) | List of CIDR blocks to allow API access to Vault instances. | `list(string)` | `[]` | no |
| <a name="input_net_ingress_vault_security_group_ids"></a> [net\_ingress\_vault\_security\_group\_ids](#input\_net\_ingress\_vault\_security\_group\_ids) | List of security group IDs to allow API access to Vault instances. | `list(string)` | `[]` | no |
| <a name="input_placement_group_partition_count"></a> [placement\_group\_partition\_count](#input\_placement\_group\_partition\_count) | The number of partitions for the placement group. This can only be set when `placement_group_strategy` is `partition`. | `number` | `null` | no |
| <a name="input_placement_group_spread_level"></a> [placement\_group\_spread\_level](#input\_placement\_group\_spread\_level) | The spread level for the placement group when `placement_group_strategy` is `spread`. Valid values are `host` and `rack`. | `string` | `"rack"` | no |
| <a name="input_placement_group_strategy"></a> [placement\_group\_strategy](#input\_placement\_group\_strategy) | The placement group strategy to use for the Vault nodes. Valid values are `cluster`, `partition`, and `spread`. | `string` | `"spread"` | no |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | A map containing tags to assign to all resources | `map(string)` | `{}` | no |
| <a name="input_route53_vault_hosted_zone_is_private"></a> [route53\_vault\_hosted\_zone\_is\_private](#input\_route53\_vault\_hosted\_zone\_is\_private) | Boolean indicating if `route53_vault_hosted_zone_name` is a private hosted zone. | `bool` | `false` | no |
| <a name="input_route53_vault_hosted_zone_name"></a> [route53\_vault\_hosted\_zone\_name](#input\_route53\_vault\_hosted\_zone\_name) | Route53 Hosted Zone name to create `vault_hostname` Alias record in. Required if `create_route53_vault_dns_record` is `true`. | `string` | `null` | no |
| <a name="input_stickiness_enabled"></a> [stickiness\_enabled](#input\_stickiness\_enabled) | Enable sticky sessions by client IP address for the load balancer. | `bool` | `true` | no |
| <a name="input_systemd_dir"></a> [systemd\_dir](#input\_systemd\_dir) | Path to systemd directory for unit files | `string` | `"/lib/systemd/system"` | no |
| <a name="input_vault_default_lease_ttl_duration"></a> [vault\_default\_lease\_ttl\_duration](#input\_vault\_default\_lease\_ttl\_duration) | The default lease TTL expressed as a time duration in hours, minutes and/or seconds (e.g. `4h30m10s`) | `string` | `"1h"` | no |
| <a name="input_vault_dir_bin"></a> [vault\_dir\_bin](#input\_vault\_dir\_bin) | The bin directory for the Vault binary | `string` | `"/usr/bin"` | no |
| <a name="input_vault_dir_config"></a> [vault\_dir\_config](#input\_vault\_dir\_config) | The directory for Vault server configuration file(s) | `string` | `"/etc/vault.d"` | no |
| <a name="input_vault_dir_home"></a> [vault\_dir\_home](#input\_vault\_dir\_home) | The home directory for the Vault system user | `string` | `"/opt/vault"` | no |
| <a name="input_vault_dir_logs"></a> [vault\_dir\_logs](#input\_vault\_dir\_logs) | Path to hold Vault file audit device logs | `string` | `"/var/log/vault"` | no |
| <a name="input_vault_disable_mlock"></a> [vault\_disable\_mlock](#input\_vault\_disable\_mlock) | Disable the server from executing the `mlock` syscall | `bool` | `true` | no |
| <a name="input_vault_enable_ui"></a> [vault\_enable\_ui](#input\_vault\_enable\_ui) | Enable the Vault UI | `bool` | `true` | no |
| <a name="input_vault_group_name"></a> [vault\_group\_name](#input\_vault\_group\_name) | Name of group to own Vault files and processes | `string` | `"vault"` | no |
| <a name="input_vault_health_endpoints"></a> [vault\_health\_endpoints](#input\_vault\_health\_endpoints) | The status codes to return when querying Vault's sys/health endpoint | `map(string)` | <pre>{<br/>  "activecode": "200",<br/>  "drsecondarycode": "472",<br/>  "performancestandbycode": "473",<br/>  "perfstandbyok": "true",<br/>  "sealedcode": "503",<br/>  "standbycode": "429",<br/>  "standbyok": "true",<br/>  "uninitcode": "200"<br/>}</pre> | no |
| <a name="input_vault_max_lease_ttl_duration"></a> [vault\_max\_lease\_ttl\_duration](#input\_vault\_max\_lease\_ttl\_duration) | The max lease TTL expressed as a time duration in hours, minutes and/or seconds (e.g. `4h30m10s`) | `string` | `"768h"` | no |
| <a name="input_vault_plugin_urls"></a> [vault\_plugin\_urls](#input\_vault\_plugin\_urls) | (optional list) List of Vault plugin fully qualified URLs (example ["https://releases.hashicorp.com/terraform-provider-oraclepaas/1.5.3/terraform-provider-oraclepaas_1.5.3_linux_amd64.zip"] for deployment to Vault plugins directory) | `list(string)` | `[]` | no |
| <a name="input_vault_port_api"></a> [vault\_port\_api](#input\_vault\_port\_api) | The port the Vault API will listen on | `string` | `"8200"` | no |
| <a name="input_vault_port_cluster"></a> [vault\_port\_cluster](#input\_vault\_port\_cluster) | The port the Vault cluster port will listen on | `string` | `"8201"` | no |
| <a name="input_vault_raft_auto_join_tag"></a> [vault\_raft\_auto\_join\_tag](#input\_vault\_raft\_auto\_join\_tag) | A map containing a single tag which will be used by Vault to join other nodes to the cluster. If left blank, the module will use the first entry in `tags` | `map(string)` | `null` | no |
| <a name="input_vault_raft_performance_multiplier"></a> [vault\_raft\_performance\_multiplier](#input\_vault\_raft\_performance\_multiplier) | Raft performance multiplier value. Defaults to 5, which is the default Vault value. | `number` | `5` | no |
| <a name="input_vault_seal_awskms_region"></a> [vault\_seal\_awskms\_region](#input\_vault\_seal\_awskms\_region) | The region the KMS is in. Leave null if in the same region as everything else | `string` | `null` | no |
| <a name="input_vault_seal_type"></a> [vault\_seal\_type](#input\_vault\_seal\_type) | The seal type to use for Vault | `string` | `"awskms"` | no |
| <a name="input_vault_snapshots_bucket_arn"></a> [vault\_snapshots\_bucket\_arn](#input\_vault\_snapshots\_bucket\_arn) | The ARN of the S3 bucket for auto-snapshots | `string` | `null` | no |
| <a name="input_vault_telemetry_config"></a> [vault\_telemetry\_config](#input\_vault\_telemetry\_config) | Enable telemetry for Vault | `map(string)` | `null` | no |
| <a name="input_vault_tls_disable_client_certs"></a> [vault\_tls\_disable\_client\_certs](#input\_vault\_tls\_disable\_client\_certs) | Disable client authentication for the Vault listener. Must be enabled when tls auth method is used. | `bool` | `true` | no |
| <a name="input_vault_tls_require_and_verify_client_cert"></a> [vault\_tls\_require\_and\_verify\_client\_cert](#input\_vault\_tls\_require\_and\_verify\_client\_cert) | Require a client to present a client certificate that validates against system CAs | `bool` | `false` | no |
| <a name="input_vault_user_name"></a> [vault\_user\_name](#input\_vault\_user\_name) | Name of system user to own Vault files and processes | `string` | `"vault"` | no |
| <a name="input_vault_version"></a> [vault\_version](#input\_vault\_version) | The version of Vault to use | `string` | `"1.17.3+ent"` | no |
| <a name="input_vm_boot_disk_configuration"></a> [vm\_boot\_disk\_configuration](#input\_vm\_boot\_disk\_configuration) | The disk (EBS) configuration to use for the Vault nodes | <pre>object(<br/>    {<br/>      volume_type           = string<br/>      volume_size           = number<br/>      delete_on_termination = bool<br/>      encrypted             = bool<br/>    }<br/>  )</pre> | <pre>{<br/>  "delete_on_termination": true,<br/>  "encrypted": true,<br/>  "volume_size": 30,<br/>  "volume_type": "gp3"<br/>}</pre> | no |
| <a name="input_vm_ebs_kms_key_id"></a> [vm\_ebs\_kms\_key\_id](#input\_vm\_ebs\_kms\_key\_id) | The KMS key ID to use for launch template EBS block device mappings. Leave null to use the account default EBS KMS key. | `string` | `null` | no |
| <a name="input_vm_image_id"></a> [vm\_image\_id](#input\_vm\_image\_id) | Custom AMI ID for EC2 launch template. If specified, value of `ec2_os_distro` must coincide with this custom AMI OS distro. | `string` | `null` | no |
| <a name="input_vm_instance_type"></a> [vm\_instance\_type](#input\_vm\_instance\_type) | The machine type to use for the Vault nodes | `string` | `"m7i.large"` | no |
| <a name="input_vm_key_pair_name"></a> [vm\_key\_pair\_name](#input\_vm\_key\_pair\_name) | The machine SSH key pair name to use for the cluster nodes | `string` | `null` | no |
| <a name="input_vm_vault_audit_disk_configuration"></a> [vm\_vault\_audit\_disk\_configuration](#input\_vm\_vault\_audit\_disk\_configuration) | The disk (EBS) configuration to use for the Vault nodes | <pre>object(<br/>    {<br/>      volume_type           = string<br/>      volume_size           = number<br/>      delete_on_termination = bool<br/>      encrypted             = bool<br/>    }<br/>  )</pre> | <pre>{<br/>  "delete_on_termination": true,<br/>  "encrypted": true,<br/>  "volume_size": 50,<br/>  "volume_type": "gp3"<br/>}</pre> | no |
| <a name="input_vm_vault_data_disk_configuration"></a> [vm\_vault\_data\_disk\_configuration](#input\_vm\_vault\_data\_disk\_configuration) | The disk (EBS) configuration to use for the Vault nodes | <pre>object(<br/>    {<br/>      volume_type           = string<br/>      volume_size           = number<br/>      volume_iops           = number<br/>      volume_throughput     = number<br/>      delete_on_termination = bool<br/>      encrypted             = bool<br/>    }<br/>  )</pre> | <pre>{<br/>  "delete_on_termination": true,<br/>  "encrypted": true,<br/>  "volume_iops": 3000,<br/>  "volume_size": 100,<br/>  "volume_throughput": 125,<br/>  "volume_type": "gp3"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vault_cli_config"></a> [vault\_cli\_config](#output\_vault\_cli\_config) | n/a |
<!-- END_TF_DOCS -->
