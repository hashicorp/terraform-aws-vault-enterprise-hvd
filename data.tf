# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

data "aws_region" "current" {}

data "aws_vpc" "main" {
  id = var.net_vpc_id
}

data "aws_kms_key" "vault_unseal" {
  key_id = var.vault_seal_awskms_key_arn
}

#------------------------------------------------------------------------------
# EC2 AMI data sources
#------------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  count = var.ec2_os_distro == "ubuntu" && var.vm_image_id == null ? 1 : 0

  owners      = ["099720109477", "513442679011"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "rhel" {
  count = var.ec2_os_distro == "rhel" && var.vm_image_id == null ? 1 : 0

  owners      = ["309956199498"]
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-9.*_HVM-*-x86_64-*-Hourly2-GP3"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "al2023" {
  count = var.ec2_os_distro == "al2023" && var.vm_image_id == null ? 1 : 0

  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

#------------------------------------------------------------------------------
# Launch template
#------------------------------------------------------------------------------
locals {
  // If an AMI ID is provided via `var.vm_image_id`, use it. Otherwise,
  // use the latest AMI for the specified OS distro via `var.ec2_os_distro`.
  ami_id_list = tolist([
    var.vm_image_id,
    join("", data.aws_ami.ubuntu.*.image_id),
    join("", data.aws_ami.rhel.*.image_id),
    join("", data.aws_ami.al2023.*.image_id),
  ])
}

// Query the specific AMI being used to obtain the selected AMI's ID.
data "aws_ami" "selected" {
  filter {
    name   = "image-id"
    values = [coalesce(local.ami_id_list...)]
  }
}
