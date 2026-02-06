# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

#-----------------------------------------------------------------------------------
# Common
#-----------------------------------------------------------------------------------
variable "friendly_name_prefix" {
  type        = string
  description = "Name prefix to use when naming cloud resources"
  default     = "vault"
  # Validate length
}

variable "resource_tags" {
  type        = map(string)
  description = "A map containing tags to assign to all resources"
  default     = {}
}

variable "vault_fqdn" {
  type        = string
  description = "Fully qualified domain name to use for joining peer nodes and optionally DNS"
  nullable    = false
}

#------------------------------------------------------------------------------
# prereqs
#------------------------------------------------------------------------------
variable "sm_vault_license_arn" {
  type        = string
  description = "The ARN of the license secret in AWS Secrets Manager"
  nullable    = false
}

variable "sm_vault_tls_ca_bundle" {
  type        = string
  description = "(required) The ARN of the CA bundle secret in AWS Secrets Manager, Secret should be stored as a base64-encoded string. Secret type should be plaintext."
  nullable    = true
}

variable "sm_vault_tls_cert_arn" {
  type        = string
  description = "(required) The ARN of the signed TLS certificate secret in AWS Secrets Manager, Secret should be stored as a base64-encoded string. Secret type should be plaintext."
  nullable    = false
}

variable "sm_vault_tls_cert_key_arn" {
  type        = string
  description = "(required) The ARN of the signed TLS certificate's private key secret in AWS Secrets Manager, Secret should be stored as a base64-encoded string. Secret type should be plaintext."
  nullable    = false
}

variable "vault_seal_awskms_key_arn" {
  type        = string
  description = "The KMS key ID to use for Vault auto-unseal"
  nullable    = true
}

variable "vault_seal_awskms_region" {
  type        = string
  description = "The region the KMS is in. Leave null if in the same region as everything else"
  default     = null
}

#------------------------------------------------------------------------------
# Vault configuration settings
#------------------------------------------------------------------------------
variable "vault_version" {
  type        = string
  description = "The version of Vault to use"
  default     = "1.17.3+ent"
}

variable "vault_disable_mlock" {
  type        = bool
  description = "Disable the server from executing the `mlock` syscall"
  default     = true
}

variable "vault_enable_ui" {
  type        = bool
  description = "Enable the Vault UI"
  default     = true
}

variable "vault_default_lease_ttl_duration" {
  type        = string
  description = "The default lease TTL expressed as a time duration in hours, minutes and/or seconds (e.g. `4h30m10s`)"
  default     = "1h"

  validation {
    condition     = can(regex("^([[:digit:]]+h)*([[:digit:]]+m)*([[:digit:]]+s)*$", var.vault_default_lease_ttl_duration))
    error_message = "Value must be a combination of hours (h), minutes (m) and/or seconds (s). e.g. `4h30m10s`"
  }
}

variable "vault_max_lease_ttl_duration" {
  type        = string
  description = "The max lease TTL expressed as a time duration in hours, minutes and/or seconds (e.g. `4h30m10s`)"
  default     = "768h"

  validation {
    condition     = can(regex("^([[:digit:]]+h)*([[:digit:]]+m)*([[:digit:]]+s)*$", var.vault_max_lease_ttl_duration))
    error_message = "Value must be a combination of hours (h), minutes (m) and/or seconds (s). e.g. `4h30m10s`"
  }
}

variable "vault_port_api" {
  type        = string
  description = "The port the Vault API will listen on"
  default     = "8200"
}

variable "vault_port_cluster" {
  type        = string
  description = "The port the Vault cluster port will listen on"
  default     = "8201"
}
variable "vault_telemetry_config" {
  type        = map(string)
  description = "Enable telemetry for Vault"
  default     = null

  validation {
    condition     = var.vault_telemetry_config == null || can(tomap(var.vault_telemetry_config))
    error_message = "Telemetry config must be provided as a map of key-value pairs."
  }

}
variable "vault_tls_disable_client_certs" {
  type        = bool
  description = "Disable client authentication for the Vault listener. Must be enabled when tls auth method is used."
  default     = true
}

variable "vault_tls_require_and_verify_client_cert" {
  type        = bool
  description = "Require a client to present a client certificate that validates against system CAs"
  default     = false
}

variable "vault_seal_type" {
  type        = string
  description = "The seal type to use for Vault"
  default     = "awskms"

  validation {
    condition     = var.vault_seal_type == "shamir" || var.vault_seal_type == "awskms"
    error_message = "The seal type must be shamir or awskms."
  }
}

variable "vault_raft_auto_join_tag" {
  type        = map(string)
  description = "A map containing a single tag which will be used by Vault to join other nodes to the cluster. If left blank, the module will use the first entry in `tags`"
  default     = null
}

variable "vault_raft_performance_multiplier" {
  description = "Raft performance multiplier value. Defaults to 5, which is the default Vault value."
  type        = number
  default     = 5

  validation {
    condition     = var.vault_raft_performance_multiplier >= 1 && var.vault_raft_performance_multiplier <= 10
    error_message = "Raft performance multiplier must be an integer between 1 and 10."
  }

  validation {
    condition     = var.vault_raft_performance_multiplier == floor(var.vault_raft_performance_multiplier)
    error_message = "Raft performance multiplier must be an integer."
  }
}

#------------------------------------------------------------------------------
# System paths and settings
#------------------------------------------------------------------------------
variable "additional_package_names" {
  type        = set(string)
  description = "List of additional repository package names to install"
  default     = []
}

variable "vault_user_name" {
  type        = string
  description = "Name of system user to own Vault files and processes"
  default     = "vault"
}

variable "vault_group_name" {
  type        = string
  description = "Name of group to own Vault files and processes"
  default     = "vault"
}

variable "systemd_dir" {
  type        = string
  description = "Path to systemd directory for unit files"
  default     = "/lib/systemd/system"
}

variable "vault_dir_bin" {
  type        = string
  description = "The bin directory for the Vault binary"
  default     = "/usr/bin"
}

variable "vault_dir_config" {
  type        = string
  description = "The directory for Vault server configuration file(s)"
  default     = "/etc/vault.d"
}

variable "vault_dir_home" {
  type        = string
  description = "The home directory for the Vault system user"
  default     = "/opt/vault"
}

variable "vault_dir_logs" {
  type        = string
  description = "Path to hold Vault file audit device logs"
  default     = "/var/log/vault"
}

variable "vault_plugin_urls" {
  type        = list(string)
  default     = []
  description = "(optional list) List of Vault plugin fully qualified URLs (example [\"https://releases.hashicorp.com/terraform-provider-oraclepaas/1.5.3/terraform-provider-oraclepaas_1.5.3_linux_amd64.zip\"] for deployment to Vault plugins directory)"
}

variable "vault_snapshots_bucket_arn" {
  type        = string
  description = "The ARN of the S3 bucket for auto-snapshots"
  default     = null
}

#-----------------------------------------------------------------------------------
# Networking
#-----------------------------------------------------------------------------------
variable "net_vpc_id" {
  type        = string
  description = "(required) The VPC ID to host the cluster in"
  nullable    = false
}

variable "net_vault_subnet_ids" {
  type        = list(string)
  description = "(required) The subnet IDs in the VPC to host the Vault servers in"
  nullable    = false
  # Validate for list of 3
}

variable "net_lb_subnet_ids" {
  type        = list(string)
  description = "The subnet IDs in the VPC to host the load balancer in."
  nullable    = false
  # Validate for list of 3
}

variable "net_ingress_ssh_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks to allow SSH access to Vault instances."
  default     = []
}

variable "net_ingress_ssh_security_group_ids" {
  type        = list(string)
  description = "List of CIDR blocks to allow SSH access to Vault instances."
  default     = []
}

variable "net_ingress_vault_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks to allow API access to Vault."
  default     = []
}

variable "net_ingress_vault_security_group_ids" {
  type        = list(string)
  description = "List of CIDR blocks to allow API access to Vault."
  default     = []
}

#-----------------------------------------------------------------------------------
# DNS Route53
#-----------------------------------------------------------------------------------

variable "create_route53_vault_dns_record" {
  type        = bool
  description = "Boolean to create Route53 Alias Record for `vault_hostname` resolving to Load Balancer DNS name. If `true`, `route53_vault_hosted_zone_name` is also required."
  default     = false
}

variable "route53_vault_hosted_zone_name" {
  type        = string
  description = "Route53 Hosted Zone name to create `vault_hostname` Alias record in. Required if `create_route53_vault_dns_record` is `true`."
  default     = null

  validation {
    condition     = var.create_route53_vault_dns_record ? var.route53_vault_hosted_zone_name != null : true
    error_message = "Value must be set when `create_route53_vault_dns_record` is `true`."
  }
}

variable "route53_vault_hosted_zone_is_private" {
  type        = bool
  description = "Boolean indicating if `route53_vault_hosted_zone_name` is a private hosted zone."
  default     = false
}


#-----------------------------------------------------------------------------------
# Compute
#-----------------------------------------------------------------------------------
variable "asg_node_count" {
  type        = number
  description = "The number of nodes to create in the pool."
  default     = 6
}

variable "asg_health_check_type" {
  type        = string
  description = "Defines how autoscaling health checking is done"
  default     = "EC2"

  validation {
    condition     = var.asg_health_check_type == "EC2" || var.asg_health_check_type == "ELB"
    error_message = "The health check type must be either EC2 or ELB."
  }
}

variable "asg_health_check_grace_period" {
  type        = string
  description = "The amount of time to expire before the autoscaling group terminates an unhealthy node is terminated"
  default     = 600
}

variable "vm_instance_type" {
  type        = string
  description = "The machine type to use for the Vault nodes"
  default     = "m7i.large"
}


variable "vm_image_id" {
  type        = string
  description = "Custom AMI ID for EC2 launch template. If specified, value of `ec2_os_distro` must coincide with this custom AMI OS distro."
  default     = null

  validation {
    condition     = try((length(var.vm_image_id) > 4 && substr(var.vm_image_id, 0, 4) == "ami-"), var.vm_image_id == null)
    error_message = "Value must start with \"ami-\"."
  }

  validation {
    condition     = var.ec2_os_distro == "centos" ? var.vm_image_id != null : true
    error_message = "Value must be set to a CentOS AMI ID when `ec2_os_distro` is `centos`."
  }
}
variable "ec2_os_distro" {
  type        = string
  description = "Linux OS distribution type for EC2 instance. Choose from `al2023`, `ubuntu`, `rhel`, `centos`."
  default     = "ubuntu"

  validation {
    condition     = contains(["ubuntu", "rhel", "al2023", "centos"], var.ec2_os_distro)
    error_message = "Valid values are `ubuntu`, `rhel`, `al2023`, or `centos`."
  }

}

variable "vm_boot_disk_configuration" {
  description = "The disk (EBS) configuration to use for the Vault nodes"
  type = object(
    {
      volume_type           = string
      volume_size           = number
      delete_on_termination = bool
      encrypted             = bool
    }
  )
  default = {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }
}

variable "vm_vault_data_disk_configuration" {
  description = "The disk (EBS) configuration to use for the Vault nodes"
  type = object(
    {
      volume_type           = string
      volume_size           = number
      volume_iops           = number
      volume_throughput     = number
      delete_on_termination = bool
      encrypted             = bool
    }
  )
  default = {
    volume_type           = "gp3"
    volume_size           = 100
    volume_iops           = 3000
    volume_throughput     = 125
    delete_on_termination = true
    encrypted             = true
  }
}

variable "vm_vault_audit_disk_configuration" {
  description = "The disk (EBS) configuration to use for the Vault nodes"
  type = object(
    {
      volume_type           = string
      volume_size           = number
      delete_on_termination = bool
      encrypted             = bool
    }
  )
  default = {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true
  }
}

variable "vm_key_pair_name" {
  type        = string
  description = "The machine SSH key pair name to use for the cluster nodes"
  default     = null
}

variable "custom_startup_script_template" {
  type        = string
  description = "Filename of a custom Vault Install script template to use in place of the built-in user_data script. The file must exist within a directory named './templates' in your current working directory."
  default     = null

  validation {
    condition     = var.custom_startup_script_template != null ? fileexists("${path.cwd}/templates/${var.custom_startup_script_template}") : true
    error_message = "File not found. Ensure the file exists within a directory named './templates' relative to your current working directory."
  }
}
variable "ec2_allow_ssm" {
  type        = bool
  description = "Boolean to attach the `AmazonSSMManagedInstanceCore` policy to the Vault instance role (`aws_iam_role.vault_iam_role`), allowing the SSM agent (if present) to function."
  default     = false
}

#-----------------------------------------------------------------------------------
# IAM variables
#-----------------------------------------------------------------------------------
variable "iam_role_path" {
  type        = string
  description = "Path for IAM entities"
  default     = "/"
}

variable "iam_role_permissions_boundary_arn" {
  type        = string
  description = "The ARN of the policy that is used to set the permissions boundary for the role"
  default     = null
}

#-----------------------------------------------------------------------------------
# Load Balancer variables
#-----------------------------------------------------------------------------------
variable "load_balancing_scheme" {
  type        = string
  description = "Type of load balancer to use (INTERNAL, EXTERNAL, or NONE)"
  default     = "INTERNAL"

  validation {
    condition     = var.load_balancing_scheme == "INTERNAL" || var.load_balancing_scheme == "EXTERNAL" || var.load_balancing_scheme == "NONE"
    error_message = "The load balancing scheme must be INTERNAL, EXTERNAL, or NONE."
  }
}

variable "vault_health_endpoints" {
  type        = map(string)
  description = "The status codes to return when querying Vault's sys/health endpoint"
  default = {
    standbyok              = "true"
    perfstandbyok          = "true"
    activecode             = "200"
    standbycode            = "429"
    drsecondarycode        = "472"
    performancestandbycode = "473"
    sealedcode             = "503"

    # Allow unitialized clusters to be considered healthy. Default is 501.
    uninitcode = "200"
  }
}

variable "health_check_interval" {
  type        = number
  description = "Approximate amount of time, in seconds, between health checks of an individual target. The range is 5-300."
  default     = 5

  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "The health check interval must be between 5 and 300."
  }
}

variable "health_check_timeout" {
  type        = number
  description = "Amount of time, in seconds, during which no response from a target means a failed health check. The range is 2–120 seconds."
  default     = 3

  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 120
    error_message = "The health check timeout must be between 2 and 120."
  }
}

variable "health_check_deregistration_delay" {
  type        = number
  description = "Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds."
  default     = 15

  validation {
    condition     = var.health_check_deregistration_delay >= 0 && var.health_check_deregistration_delay <= 3600
    error_message = "The health check deregistration delay must be between 0 and 3600."
  }
}

variable "stickiness_enabled" {
  type        = bool
  description = "Enable sticky sessions by client IP address for the load balancer."
  default     = true
}
