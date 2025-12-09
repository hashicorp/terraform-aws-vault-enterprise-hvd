# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

resource "aws_iam_role" "vault_iam_role" {
  name                 = format("%s-role", var.friendly_name_prefix)
  path                 = var.iam_role_path
  assume_role_policy   = file("${path.module}/templates/vault-server-role.json.tpl")
  permissions_boundary = var.iam_role_permissions_boundary_arn
  tags                 = var.resource_tags
}

resource "aws_iam_instance_profile" "vault_iam_instance_profile" {
  name_prefix = format("%s-profile", var.friendly_name_prefix)
  role        = aws_iam_role.vault_iam_role.name
  path        = var.iam_role_path
  tags        = var.resource_tags
}

resource "aws_iam_role_policy" "main" {
  name = format("%s-policy", var.friendly_name_prefix)
  role = aws_iam_role.vault_iam_role.id

  policy = templatefile("${path.module}/templates/vault-server-role-policy.json.tpl", {
    vault_license_secret       = var.sm_vault_license_arn == null ? "" : var.sm_vault_license_arn,
    vault_ca_bundle_secret     = var.sm_vault_tls_ca_bundle == null ? "" : var.sm_vault_tls_ca_bundle,
    vault_signed_cert_secret   = var.sm_vault_tls_cert_arn == null ? "" : var.sm_vault_tls_cert_arn,
    vault_private_key_secret   = var.sm_vault_tls_cert_key_arn == null ? "" : var.sm_vault_tls_cert_key_arn,
    vault_seal_type            = "awskms" #var.vault_seal_type,
    vault_kms_key_arn          = data.aws_kms_key.vault_unseal
    vault_snapshots_bucket_arn = var.vault_snapshots_bucket_arn == null ? "" : var.vault_snapshots_bucket_arn,
  })
}
