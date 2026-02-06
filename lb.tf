# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

resource "aws_lb_target_group" "vault_api" {
  count                = var.load_balancing_scheme == "NONE" ? 0 : 1
  name                 = format("%s-vault", var.friendly_name_prefix)
  target_type          = "instance"
  port                 = var.vault_port_api
  protocol             = "TCP"
  vpc_id               = var.net_vpc_id
  deregistration_delay = var.health_check_deregistration_delay
  tags                 = var.resource_tags

  health_check {
    protocol = "HTTPS"
    port     = "traffic-port"
    timeout  = var.health_check_timeout
    interval = var.health_check_interval

    path = format("/v1/sys/health?standbyok=%s&perfstandbyok=%s&activecode=%s&standbycode=%s&drsecondarycode=%s&performancestandbycode=%s&sealedcode=%s&uninitcode=%s",
      var.vault_health_endpoints["standbyok"],
      var.vault_health_endpoints["perfstandbyok"],
      var.vault_health_endpoints["activecode"],
      var.vault_health_endpoints["standbycode"],
      var.vault_health_endpoints["drsecondarycode"],
      var.vault_health_endpoints["performancestandbycode"],
      var.vault_health_endpoints["sealedcode"],
    var.vault_health_endpoints["uninitcode"])
  }

  stickiness {
    type    = "source_ip" # Only option for NLBs
    enabled = var.stickiness_enabled
  }
}

resource "aws_lb_listener" "vault_api" {
  count             = var.load_balancing_scheme == "NONE" ? 0 : 1
  load_balancer_arn = aws_lb.vault_lb[0].id
  port              = var.vault_port_api
  protocol          = "TCP"
  tags              = var.resource_tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault_api[0].arn
  }
}

resource "aws_security_group" "lb" {
  count       = var.load_balancing_scheme == "NONE" ? 0 : 1
  name        = format("%s-lb-sg", var.friendly_name_prefix)
  description = "Security group for Load Balancer"
  vpc_id      = var.net_vpc_id
  tags        = var.resource_tags
}

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

resource "aws_lb" "vault_lb" {
  count              = var.load_balancing_scheme == "NONE" ? 0 : 1
  name               = format("%s", var.friendly_name_prefix)
  internal           = var.load_balancing_scheme == "INTERNAL" ? true : false
  load_balancer_type = "network"
  subnets            = var.net_lb_subnet_ids == null ? var.net_vault_subnet_ids : var.net_lb_subnet_ids
  tags               = var.resource_tags
  security_groups    = [aws_security_group.lb[0].id]
}
