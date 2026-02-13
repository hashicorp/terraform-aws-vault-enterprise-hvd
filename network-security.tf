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
  count       = var.net_ingress_vault_cidr_blocks != null && length(var.net_ingress_vault_cidr_blocks) > 0 ? 1 : 0
  type        = "ingress"
  from_port   = var.vault_port_api
  to_port     = var.vault_port_api
  protocol    = "tcp"
  cidr_blocks = var.net_ingress_vault_cidr_blocks
  description = "Allow API access to Vault nodes"

  security_group_id = aws_security_group.main[0].id
}

resource "aws_security_group_rule" "ingress_vault_api_sg_ids" {
  for_each                 = toset(var.net_ingress_vault_security_group_ids == null ? [] : var.net_ingress_vault_security_group_ids)
  type                     = "ingress"
  from_port                = var.vault_port_api
  to_port                  = var.vault_port_api
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "Allow API access to Vault nodes from specified security groups"

  security_group_id = aws_security_group.main[0].id
}

resource "aws_security_group_rule" "ingress_vault_cluster" {
  count       = 1 # var.security_group_ids == null ? 1 : 0
  type        = "ingress"
  from_port   = var.vault_port_cluster
  to_port     = var.vault_port_cluster
  self        = true
  protocol    = "tcp"
  description = "Allow Vault nodes to communicate with each other in HA mode"

  security_group_id = aws_security_group.main[0].id
}

resource "aws_security_group_rule" "ingress_vault_api" {
  count       = 1 # var.security_group_ids == null ? 1 : 0
  type        = "ingress"
  from_port   = var.vault_port_api
  to_port     = var.vault_port_api
  self        = true
  protocol    = "tcp"
  description = "Allow Vault nodes to communicate with each other on the API port for auto_join"

  security_group_id = aws_security_group.main[0].id
}

resource "aws_security_group_rule" "ingress_ssh_cidr" {
  count       = var.net_ingress_ssh_cidr_blocks != null && length(var.net_ingress_ssh_cidr_blocks) > 0 ? 1 : 0
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.net_ingress_ssh_cidr_blocks
  description = "Allow SSH access to Vault nodes"

  security_group_id = aws_security_group.main[0].id
}

resource "aws_security_group_rule" "ingress_ssh_sg_ids" {
  for_each                 = toset(var.net_ingress_ssh_security_group_ids == null ? [] : var.net_ingress_ssh_security_group_ids)
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "Allow SSH access to Vault nodes from specified security groups"

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

# LB related security groups and rules
resource "aws_security_group" "lb" {
  count       = var.load_balancing_scheme == "NONE" ? 0 : 1
  name        = format("%s-lb-sg", var.friendly_name_prefix)
  description = "Security group for Load Balancer"
  vpc_id      = var.net_vpc_id
  tags        = var.resource_tags
}

# Necessary Security Group rules for LB to communicate with Vault instances
resource "aws_security_group_rule" "egress_lb" {
  count                    = var.load_balancing_scheme == "NONE" ? 0 : 1
  type                     = "egress"
  from_port                = var.vault_port_api
  to_port                  = var.vault_port_api
  source_security_group_id = aws_security_group.main[0].id
  protocol                 = "tcp"

  description = "Allow egress traffic from LB to Vault API ports"

  security_group_id = aws_security_group.lb[0].id
}

resource "aws_security_group_rule" "ingress_vault_api_lb" {
  count                    = var.load_balancing_scheme == "NONE" ? 0 : 1
  type                     = "ingress"
  from_port                = var.vault_port_api
  to_port                  = var.vault_port_api
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb[0].id
  description              = "Allow API access to Vault nodes from load balancer"

  security_group_id = aws_security_group.main[0].id
}

resource "aws_security_group_rule" "egress_lb_cluster" {
  count                    = var.load_balancing_scheme == "NONE" || !var.enable_vault_cluster_port_listener ? 0 : 1
  type                     = "egress"
  from_port                = var.vault_port_cluster
  to_port                  = var.vault_port_cluster
  source_security_group_id = aws_security_group.main[0].id
  protocol                 = "tcp"
  description              = "Allow egress traffic from LB to Vault cluster ports"

  security_group_id = aws_security_group.lb[0].id
}

resource "aws_security_group_rule" "ingress_vault_cluster_lb" {
  count                    = var.load_balancing_scheme == "NONE" || !var.enable_vault_cluster_port_listener ? 0 : 1
  type                     = "ingress"
  from_port                = var.vault_port_cluster
  to_port                  = var.vault_port_cluster
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb[0].id
  description              = "Allow cluster port access to Vault nodes from load balancer"

  security_group_id = aws_security_group.main[0].id
}
# END Necessary Security Group rules for LB to communicate with Vault instances

# Necessary Security Group rules for consumer to reach Vault LB
resource "aws_security_group_rule" "ingress_vault_api_lb_cidr" {
  count       = var.load_balancing_scheme != "NONE" && var.net_ingress_lb_cidr_blocks != null && length(var.net_ingress_lb_cidr_blocks) > 0 ? 1 : 0
  type        = "ingress"
  from_port   = var.vault_port_api
  to_port     = var.vault_port_api
  protocol    = "tcp"
  cidr_blocks = var.net_ingress_lb_cidr_blocks
  description = "Allow API access to Vault API via Load Balancer"

  security_group_id = aws_security_group.lb[0].id
}

resource "aws_security_group_rule" "ingress_vault_cluster_lb_cidr" {
  count       = var.load_balancing_scheme != "NONE" && var.enable_vault_cluster_port_listener && var.net_ingress_lb_cluster_cidr_blocks != null && length(var.net_ingress_lb_cluster_cidr_blocks) > 0 ? 1 : 0
  type        = "ingress"
  from_port   = var.vault_port_cluster
  to_port     = var.vault_port_cluster
  protocol    = "tcp"
  cidr_blocks = var.net_ingress_lb_cluster_cidr_blocks
  description = "Allow cluster port access to Vault via Load Balancer"

  security_group_id = aws_security_group.lb[0].id
}

resource "aws_security_group_rule" "ingress_vault_cluster_lb_sg_ids" {
  for_each                 = toset(var.load_balancing_scheme == "NONE" || !var.enable_vault_cluster_port_listener || var.net_ingress_lb_cluster_security_group_ids == null ? [] : var.net_ingress_lb_cluster_security_group_ids)
  type                     = "ingress"
  from_port                = var.vault_port_cluster
  to_port                  = var.vault_port_cluster
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "Allow cluster port access to Vault via Load Balancer from specified security groups"

  security_group_id = aws_security_group.lb[0].id
}

resource "aws_security_group_rule" "ingress_vault_api_lb_sg_ids" {
  for_each                 = toset(var.load_balancing_scheme == "NONE" || var.net_ingress_lb_security_group_ids == null ? [] : var.net_ingress_lb_security_group_ids)
  type                     = "ingress"
  from_port                = var.vault_port_api
  to_port                  = var.vault_port_api
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "Allow API access to Vault API via Load Balancer from specified security groups"

  security_group_id = aws_security_group.lb[0].id
}
# END Necessary Security Group rules for consumer to reach Vault LB
