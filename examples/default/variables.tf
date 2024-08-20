variable "friendly_name_prefix" {
  type        = string
  description = "Name prefix to use when naming cloud resources"
  default     = "vault"
}

variable "vault_fqdn" {
  type        = string
  description = "Fully qualified domain name to use for joining peer nodes and optionally DNS"
  nullable    = false
}

variable "net_vpc_id" {
  type        = string
  description = "(required) The VPC ID to host the cluster in"
  nullable    = false
}

variable "load_balancing_scheme" {
  type        = string
  description = "Type of load balancer to use (INTERNAL, EXTERNAL, or NONE)"
  default     = "INTERNAL"

  validation {
    condition     = var.load_balancing_scheme == "INTERNAL" || var.load_balancing_scheme == "EXTERNAL" || var.load_balancing_scheme == "NONE"
    error_message = "The load balancing scheme must be INTERNAL, EXTERNAL, or NONE."
  }
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

variable "net_ingress_vault_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks to allow API access to Vault."
  default     = []
}

variable "sm_vault_license_arn" {
  type        = string
  description = "The ARN of the license secret in AWS Secrets Manager"
  nullable    = false
}

variable "sm_vault_tls_ca_bundle" {
  type        = string
  description = "(required) The ARN of the CA bundle secret in AWS Secrets Manager"
  nullable    = true
}

variable "sm_vault_tls_cert_arn" {
  type        = string
  description = "(required) The ARN of the signed TLS certificate secret in AWS Secrets Manager"
  nullable    = false
}

variable "sm_vault_tls_cert_key_arn" {
  type        = string
  description = "(required) The ARN of the signed TLS certificate's private key secret in AWS Secrets Manager"
  nullable    = false
}

variable "vault_seal_awskms_key_arn" {
  type        = string
  description = "The KMS key ID to use for Vault auto-unseal"
  nullable    = true
}

variable "vm_key_pair_name" {
  type        = string
  description = "The machine SSH key pair name to use for the cluster nodes"
  default     = null
}
