# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

resource "aws_security_group" "main" {
  count       = 1 # var.security_group_ids == null ? 1 : 0
  name        = format("%s-sg", var.friendly_name_prefix)
  description = "Security group to allow inbound SSH and Vault API connections"
  vpc_id      = var.net_vpc_id
  tags        = var.resource_tags
}

resource "aws_security_group_rule" "ingress_vault_api_cidr" {
  count       = 1 # var.security_group_ids == null ? 1 : 0
  type        = "ingress"
  from_port   = 8200 # var.vault_port_api
  to_port     = 8200 # var.vault_port_api
  protocol    = "tcp"
  cidr_blocks = var.net_ingress_vault_cidr_blocks
  description = "Allow API access to Vault nodes"

  security_group_id = aws_security_group.main[0].id
}

# resource "aws_security_group_rule" "ingress_vault_api_sg_ids" {
#   count     = 1 # var.security_group_ids == null ? 1 : 0
#   type      = "ingress"
#   from_port = 8200 # var.vault_port_api
#   to_port   = 8200 # var.vault_port_api
#   protocol  = "tcp"
#   cidr_blocks = concat([data.aws_vpc.vault_vpc.cidr_block], var.ingress_vault_cidr_blocks)
#   description = "Allow API access to Vault nodes"

#   security_group_id = aws_security_group.main[0].id
# }

resource "aws_security_group_rule" "ingress_vault_cluster" {
  count       = 1 # var.security_group_ids == null ? 1 : 0
  type        = "ingress"
  from_port   = 8201 # var.vault_port_cluster
  to_port     = 8201 # var.vault_port_cluster
  self        = true
  protocol    = "tcp"
  description = "Allow Vault nodes to communicate with each other in HA mode"

  security_group_id = aws_security_group.main[0].id
}

resource "aws_security_group_rule" "ingress_ssh_cidr" {
  count       = 1 # var.security_group_ids == null ? 1 : 0
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.net_ingress_ssh_cidr_blocks
  description = "Allow SSH access to Vault nodes"

  security_group_id = aws_security_group.main[0].id
}

resource "aws_security_group_rule" "egress_all" {
  count       = 1 # var.security_group_ids == null ? 1 : 0
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all egress traffic"

  security_group_id = aws_security_group.main[0].id
}
