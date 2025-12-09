# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

module "default_example" {
  source = "../.."

  #------------------------------------------------------------------------------
  # Common
  #------------------------------------------------------------------------------
  friendly_name_prefix = var.friendly_name_prefix
  vault_fqdn           = var.vault_fqdn

  #------------------------------------------------------------------------------
  # Networking
  #------------------------------------------------------------------------------
  net_vpc_id                    = var.net_vpc_id
  load_balancing_scheme         = var.load_balancing_scheme
  net_vault_subnet_ids          = var.net_vault_subnet_ids
  net_lb_subnet_ids             = var.net_lb_subnet_ids
  net_ingress_vault_cidr_blocks = var.net_ingress_vault_cidr_blocks
  net_ingress_ssh_cidr_blocks   = var.net_ingress_ssh_cidr_blocks

  #------------------------------------------------------------------------------
  # AWS Secrets Manager installation secrets and AWS KMS unseal key
  #------------------------------------------------------------------------------
  sm_vault_license_arn      = var.sm_vault_license_arn
  sm_vault_tls_cert_arn     = var.sm_vault_tls_cert_arn
  sm_vault_tls_cert_key_arn = var.sm_vault_tls_cert_key_arn
  sm_vault_tls_ca_bundle    = var.sm_vault_tls_ca_bundle
  vault_seal_awskms_key_arn = var.vault_seal_awskms_key_arn

  #------------------------------------------------------------------------------
  # Compute
  #------------------------------------------------------------------------------
  vm_key_pair_name = var.vm_key_pair_name
  vm_instance_type = "t3a.medium"
  asg_node_count   = 3
}