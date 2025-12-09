# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

locals {
  vault_seal_attributes = {
    region     = var.vault_seal_awskms_region == null ? data.aws_region.current.name : var.vault_seal_awskms_region
    kms_key_id = var.vault_seal_awskms_key_arn
  }
}
