# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

output "vault_load_balancer_name" {
  value       = var.load_balancing_scheme == "NONE" ? null : aws_lb.vault_lb[0].dns_name
  description = "The DNS name of the load balancer."
}

output "vault_load_balancer_security_group_id" {
  value       = var.load_balancing_scheme == "NONE" ? null : aws_security_group.lb[0].id
  description = "The ID of the load balancer security group. Allow ingress to this group on 8200 to access Vault through the LB."
}

output "vault_cli_config" {
  description = "Environment variables to configure the Vault CLI"
  value       = <<-EOF
    %{if var.load_balancing_scheme != "NONE"~}
    export VAULT_ADDR=https://${aws_lb.vault_lb[0].dns_name}:8200
    %{else~}
    # No load balancer created; set VAULT_ADDR to the IPV4 address of any Vault instance
    export VAULT_ADDR=https://<instance-ipv4>:8200
    %{endif~}
    export VAULT_TLS_SERVER_NAME=${var.vault_fqdn}
    %{if var.sm_vault_tls_ca_bundle != null~}
    export VAULT_CACERT=<path/to/ca-certificate>
    %{endif~}
  EOF
}
