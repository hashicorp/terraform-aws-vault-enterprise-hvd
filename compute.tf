# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

locals {
  vault_install_tpl           = var.custom_startup_script_template != null ? "${path.cwd}/templates/${var.custom_startup_script_template}" : "${path.module}/templates/install-vault.sh.tpl"
  user_data_template_rendered = templatefile(local.vault_install_tpl, local.vault_user_data_template_vars)
  vault_user_data_template_vars = {
    aws_region = data.aws_region.current.name,
    # system paths and settings
    systemd_dir              = var.systemd_dir,
    vault_dir_bin            = var.vault_dir_bin,
    vault_dir_config         = var.vault_dir_config,
    vault_dir_home           = var.vault_dir_home,
    vault_dir_logs           = var.vault_dir_logs,
    vault_user_name          = var.vault_user_name,
    vault_group_name         = var.vault_group_name,
    additional_package_names = join(" ", var.additional_package_names)

    # installation secrets
    sm_vault_license_arn      = var.sm_vault_license_arn,
    sm_vault_tls_cert_arn     = var.sm_vault_tls_cert_arn,
    sm_vault_tls_cert_key_arn = var.sm_vault_tls_cert_key_arn,
    sm_vault_tls_ca_bundle    = var.sm_vault_tls_ca_bundle == null ? "NONE" : var.sm_vault_tls_ca_bundle

    # Vault settings
    vault_fqdn                               = var.vault_fqdn,
    vault_version                            = var.vault_version,
    vault_disable_mlock                      = var.vault_disable_mlock,
    vault_enable_ui                          = var.vault_enable_ui,
    vault_default_lease_ttl_duration         = var.vault_default_lease_ttl_duration,
    vault_max_lease_ttl_duration             = var.vault_max_lease_ttl_duration,
    vault_port_api                           = var.vault_port_api,
    vault_port_cluster                       = var.vault_port_cluster,
    vault_telemetry_config                   = var.vault_telemetry_config == null ? {} : var.vault_telemetry_config,
    vault_tls_require_and_verify_client_cert = var.vault_tls_require_and_verify_client_cert,
    vault_tls_disable_client_certs           = var.vault_tls_disable_client_certs,
    vault_seal_type                          = var.vault_seal_type,
    vault_seal_attributes                    = local.vault_seal_attributes,
    vault_raft_performance_multiplier        = var.vault_raft_performance_multiplier

    vault_plugin_urls   = var.vault_plugin_urls
    auto_join_tag_key   = var.vault_raft_auto_join_tag == null ? "aws:autoscaling:groupName" : keys(var.vault_raft_auto_join_tag)[0],
    auto_join_tag_value = var.vault_raft_auto_join_tag == null ? format("%s-asg", var.friendly_name_prefix) : values(var.vault_raft_auto_join_tag)[0],

  }
}

resource "aws_launch_template" "main" {
  name          = format("%s-lt", var.friendly_name_prefix)
  image_id      = data.aws_ami.selected.id
  instance_type = var.vm_instance_type
  key_name      = var.vm_key_pair_name

  update_default_version = true
  tags                   = var.resource_tags
  user_data              = base64gzip(local.user_data_template_rendered)

  # root
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = var.vm_boot_disk_configuration.volume_type
      volume_size           = var.vm_boot_disk_configuration.volume_size
      delete_on_termination = var.vm_boot_disk_configuration.delete_on_termination
      encrypted             = var.vm_vault_data_disk_configuration.encrypted
    }
  }

  # vault-data
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_type           = var.vm_vault_data_disk_configuration.volume_type
      volume_size           = var.vm_vault_data_disk_configuration.volume_size
      iops                  = var.vm_vault_data_disk_configuration.volume_iops
      throughput            = var.vm_vault_data_disk_configuration.volume_throughput
      delete_on_termination = var.vm_vault_data_disk_configuration.delete_on_termination
      encrypted             = var.vm_vault_data_disk_configuration.encrypted
    }
  }

  # vault-audit
  block_device_mappings {
    device_name = "/dev/sdg"

    ebs {
      volume_type           = var.vm_vault_audit_disk_configuration.volume_type
      volume_size           = var.vm_vault_audit_disk_configuration.volume_size
      delete_on_termination = var.vm_vault_audit_disk_configuration.delete_on_termination
      encrypted             = var.vm_vault_audit_disk_configuration.encrypted
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.vault_iam_instance_profile.name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge({ "Name" = format("%s", var.friendly_name_prefix) }, var.resource_tags)
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge({ "Name" = format("%s", var.friendly_name_prefix) }, var.resource_tags)
  }

  # vpc_security_group_ids = var.security_group_ids == null ? [aws_security_group.main[0].id] : var.security_group_ids
  vpc_security_group_ids = [aws_security_group.main[0].id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_placement_group" "main" {
  name         = format("%s-pg", var.friendly_name_prefix)
  strategy     = "spread"
  spread_level = "rack"
  tags         = var.resource_tags
}

resource "aws_autoscaling_group" "main" {
  name             = format("%s-asg", var.friendly_name_prefix)
  min_size         = var.asg_node_count
  max_size         = var.asg_node_count
  desired_capacity = var.asg_node_count

  wait_for_capacity_timeout = "10m"
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = var.asg_health_check_type

  vpc_zone_identifier = var.net_vault_subnet_ids

  default_cooldown = 30
  placement_group  = aws_placement_group.main.id

  target_group_arns = var.load_balancing_scheme == "NONE" ? [] : [aws_lb_target_group.vault_api[0].arn]

  dynamic "tag" {
    for_each = var.resource_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
}
