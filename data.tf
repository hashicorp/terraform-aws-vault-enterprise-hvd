# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

data "aws_region" "current" {}
data "aws_partition" "current" {}

data "aws_vpc" "main" {
  id = var.net_vpc_id
}

data "aws_kms_key" "vault_unseal" {
  key_id = var.vault_seal_awskms_key_arn
}

data "aws_ami" "ubuntu_jammy_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
