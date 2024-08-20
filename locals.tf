locals {
  vault_seal_attributes = {
    region     = var.vault_seal_awskms_region == null ? data.aws_region.current.name : var.vault_seal_awskms_region
    kms_key_id = var.vault_seal_awskms_key_arn
  }

  launch_template_image_id = var.vm_image_id == null ? data.aws_ami.ubuntu_jammy_22_04.id : var.vm_image_id
}