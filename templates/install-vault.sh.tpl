#! /bin/bash
set -xeuo pipefail

LOGFILE="/var/log/vault-cloud-init.log"
SYSTEMD_DIR="${systemd_dir}"
VAULT_DIR_CONFIG="${vault_dir_config}"
VAULT_DIR_TLS="${vault_dir_config}/tls"
VAULT_DIR_DATA="${vault_dir_home}/data"
VAULT_DIR_LICENSE="${vault_dir_home}/license"
VAULT_DIR_PLUGINS="${vault_dir_home}/plugins"
VAULT_DIR_LOGS="${vault_dir_logs}"
VAULT_DIR_BIN="${vault_dir_bin}"
VAULT_USER="${vault_user_name}"
VAULT_GROUP="${vault_group_name}"
VAULT_INSTALL_URL="${vault_install_url}"
REQUIRED_PACKAGES="unzip"
ADDITIONAL_PACKAGES="${additional_package_names}"

function log {
  local level="$1"
  local message="$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local log_entry="$timestamp [$level] - $message"

  echo "$log_entry" | tee -a "$LOGFILE"
}

function detect_os_distro {
  local OS_DISTRO_NAME=$(grep "^NAME=" /etc/os-release | cut -d"\"" -f2)
  local OS_DISTRO_DETECTED

  case "$OS_DISTRO_NAME" in
    "Ubuntu"*)
      OS_DISTRO_DETECTED="ubuntu"
      ;;
    "CentOS Linux"*)
      OS_DISTRO_DETECTED="centos"
      ;;
    "Red Hat"*)
      OS_DISTRO_DETECTED="rhel"
      ;;
    "Amazon Linux"*)
      OS_DISTRO_DETECTED="amzn2023"
      ;;
    *)
      log "ERROR" "'$OS_DISTRO_NAME' is not a supported Linux OS distro for Vault."
      exit_script 1
  esac

  echo "$OS_DISTRO_DETECTED"
}

function install_aws_cli() {
  local os_distro="$1"

  if [[ -n "$(command -v aws)" ]]; then
    log "INFO" "Detected 'aws' (awscli) is already installed. Skipping."
  else
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -f ./awscliv2.zip && rm -rf ./aws
  fi
}

function install_packages() {
  local os_distro="$1"

  if [[ "$os_distro" == "ubuntu" ]]; then
    apt-get update -y
    apt-get install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
  elif [[ "$OS_DISTRO" == "centos" || "$OS_DISTRO" == "rhel" || "$OS_DISTRO" == "amzn2023" ]]; then
    yum install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
  else
    log "ERROR" "Unable to determine package manager"
  fi
}

function scrape_vm_info {
  echo "[INFO] Scraping virtual machine information..."

  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
  IMDSV2_TOKEN="$(curl -s -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 240" "http://169.254.169.254/latest/api/token")"
  INSTANCE_ID="$(curl -s -H "X-aws-ec2-metadata-token: $IMDSV2_TOKEN" http://169.254.169.254/latest/meta-data/instance-id)"
  REGION="$(curl -s -H "X-aws-ec2-metadata-token: $IMDSV2_TOKEN" http://169.254.169.254/latest/meta-data/placement/region)"
  AVAILABILITY_ZONE="$(curl -s -H "X-aws-ec2-metadata-token: $IMDSV2_TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)"

  echo "[INFO] Done scraping virtual machine information."
}

# user_create creates a dedicated linux user for Vault
function user_group_create {
  # Create the dedicated as a system group
  sudo groupadd --system $VAULT_GROUP

  # Create a dedicated user as a system user
  sudo useradd --system -m -d $VAULT_DIR_CONFIG -g $VAULT_GROUP $VAULT_USER
}

# directory_creates creates the necessary directories for Vault
function directory_create {
  # Define all directories needed as an array
  directories=( $VAULT_DIR_CONFIG $VAULT_DIR_DATA $VAULT_DIR_PLUGINS $VAULT_DIR_TLS $VAULT_DIR_LICENSE $VAULT_DIR_LOGS )

  # Loop through each item in the array; create the directory and configure permissions
  for directory in "$${directories[@]}"; do
    mkdir -p $directory
    sudo chown $VAULT_USER:$VAULT_GROUP $directory
    sudo chmod 750 $directory
  done
}

# install_vault_binary downloads the Vault binary and puts it in dedicated bin directory
function install_vault_binary {
  log "INFO" "Downloading Vault Enterprise binary"
  sudo curl -so $VAULT_DIR_BIN/vault.zip $VAULT_INSTALL_URL

  log "INFO" "Unzipping Vault Enterprise binary to $VAULT_DIR_BIN"
  sudo unzip $VAULT_DIR_BIN/vault.zip vault -d $VAULT_DIR_BIN
  sudo unzip $VAULT_DIR_BIN/vault.zip -x vault -d $VAULT_DIR_LICENSE

  sudo rm $VAULT_DIR_BIN/vault.zip
}

function install_vault_plugins {
  %{ for p in vault_plugin_urls ~}
  sudo curl -s --output-dir $VAULT_DIR_PLUGINS -O ${p}
  sudo unzip -o $VAULT_DIR_PLUGINS/$(basename ${p}) -d $VAULT_DIR_PLUGINS
  rm $VAULT_DIR_PLUGINS/$(basename ${p})
  chown 0700 $VAULT_DIR_PLUGINS/$(basename ${p} | cut -d '_' -f 1)
  %{ endfor ~}

  chmod 0700 $VAULT_DIR_PLUGINS
  sudo chown -R $VAULT_USER:$VAULT_GROUP $VAULT_DIR_PLUGINS
}

# fetch_tls_certificates fetches the TLS certificates from cloud's secret manager
function fetch_tls_certificates {
  log "INFO" "Retrieving TLS certificate '${sm_vault_tls_cert_arn}' from Secrets Manager."
  aws secretsmanager get-secret-value --secret-id ${sm_vault_tls_cert_arn} --region $REGION --output text --query SecretString > $VAULT_DIR_TLS/cert.pem > $VAULT_DIR_TLS/cert.pem

  log "INFO" "Retrieving TLS private key '${sm_vault_tls_cert_key_arn}' from Secrets Manager."
  aws secretsmanager get-secret-value --secret-id ${sm_vault_tls_cert_key_arn} --region $REGION --output text --query SecretString > $VAULT_DIR_TLS/key.pem

  %{ if sm_vault_tls_ca_bundle != "NONE" ~}
  log "INFO" "Retrieving CA certificate '${sm_vault_tls_ca_bundle}' from Secrets Manager."
  aws secretsmanager get-secret-value --secret-id {sm_vault_tls_ca_bundle} --region $REGION --output text --query SecretString > $VAULT_DIR_TLS/ca.pem
  %{ endif ~}

  log "INFO" "Setting certificate file permissions and ownership"
  sudo chown $VAULT_USER:$VAULT_GROUP $VAULT_DIR_TLS/*
  sudo chmod 400 $VAULT_DIR_TLS/*
}

function fetch_vault_license {
  log "INFO" "Retrieving Vault license '${sm_vault_license_arn}' from Secrets Manager."
  aws secretsmanager get-secret-value --secret-id ${sm_vault_license_arn} --region $REGION --output text --query SecretString > $VAULT_DIR_LICENSE/license.hclic

  log "INFO" "Setting license file permissions and ownership"
  sudo chown $VAULT_USER:$VAULT_GROUP $VAULT_DIR_LICENSE/license.hclic
  sudo chmod 660 $VAULT_DIR_LICENSE/license.hclic
}

function generate_vault_config {
  FULL_HOSTNAME="$(hostname -f)"

  sudo bash -c "cat > $VAULT_DIR_CONFIG/server.hcl" <<EOF
disable_mlock = ${vault_disable_mlock}
ui            = ${vault_enable_ui}

default_lease_ttl = "${vault_default_lease_ttl_duration}"
max_lease_ttl     = "${vault_max_lease_ttl_duration}"

listener "tcp" {
  address       = "[::]:${vault_port_api}"
  tls_cert_file = "$VAULT_DIR_TLS/cert.pem"
  tls_key_file  = "$VAULT_DIR_TLS/key.pem"

  tls_require_and_verify_client_cert = ${vault_tls_require_and_verify_client_cert}
  tls_disable_client_certs           = ${vault_tls_disable_client_certs}
}

storage "raft" {
  path    = "$VAULT_DIR_DATA"
  node_id = "$INSTANCE_ID"

  autopilot_redundancy_zone = "$AVAILABILITY_ZONE"

  retry_join {
    auto_join        = "provider=aws region=$REGION tag_key=${auto_join_tag_key} tag_value=${auto_join_tag_value} addr_type=private_v4"
    auto_join_scheme = "https"
%{ if sm_vault_tls_ca_bundle != "NONE" ~}
    leader_ca_cert_file   = "$VAULT_DIR_TLS/ca.pem"
%{ endif ~}
%{ if vault_fqdn != "" ~}
    leader_tls_servername = "${vault_fqdn}"
%{ else ~}
    leader_tls_servername = "$FULL_HOSTNAME"
%{ endif ~}
  }
}

license_path = "$VAULT_DIR_LICENSE/license.hclic"

%{ if vault_seal_type == "awskms" ~}
seal "awskms" {
%{ for key, value in vault_seal_attributes ~}
  ${key} = "${value}"
%{ endfor ~}
}
%{ endif ~}

api_addr      = "https://$FULL_HOSTNAME:${vault_port_api}"
cluster_addr  = "https://$FULL_HOSTNAME:${vault_port_cluster}"

plugin_directory = "$VAULT_DIR_PLUGINS"
EOF

  log "INFO" "Setting Vault server config file permissions and ownership"
  sudo chmod 600 $VAULT_DIR_CONFIG/server.hcl
  sudo chown $VAULT_USER:$VAULT_GROUP $VAULT_DIR_CONFIG/server.hcl
}

function generate_vault_systemd_unit_file {
  local kill_cmd=$(which kill)
  sudo bash -c "cat > $SYSTEMD_DIR/vault.service" <<EOF
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=$VAULT_DIR_CONFIG/server.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=$VAULT_USER
Group=$VAULT_GROUP
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=$VAULT_DIR_BIN/vault server -config=$VAULT_DIR_CONFIG/server.hcl
ExecReload=$${kill_cmd} --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

  sudo chmod 644 $SYSTEMD_DIR/vault.service

  mkdir /etc/systemd/system/vault.service.d
  bash -c "cat > /etc/systemd/system/vault.service.d/override.conf" <<EOF
[Service]
Environment="VAULT_ENABLE_FILE_PERMISSIONS_CHECK=true"
EOF
  chmod 0600 /etc/systemd/system/vault.service.d/override.conf
}

function generate_vault_logrotate {
  bash -c "cat > /etc/logrotate.d/vault" <<-EOF
  /var/log/vault/*.log {
    daily
    size 100M
    rotate 32
    dateext
    dateformat .%Y%m%d_%H%M%S
    missingok
    notifempty
    nocreate
    compress
    delaycompress
    sharedscripts
    postrotate
      systemctl reload vault > /dev/null 2>&1 || true
    endscript
  }
EOF
}

function start_enable_vault {
  sudo systemctl daemon-reload
  sudo systemctl enable vault
  sudo systemctl start vault
}

function configure_vault_cli {
  sudo bash -c "cat > /etc/profile.d/99-vault-cli-config.sh" <<EOF
export VAULT_ADDR=https://127.0.0.1:8200
%{ if vault_fqdn != "" ~}
export VAULT_TLS_SERVER_NAME="${vault_fqdn}"
%{ endif ~}
complete -C $VAULT_DIR_BIN/vault vault
EOF
}

exit_script() {
  if [[ "$1" == 0 ]]; then
    log "INFO" "Vault custom_data script finished successfully!"
  else
    log "ERROR" "Vault custom_data script finished with error code $1."
  fi

  exit "$1"
}

function prepare_disk() {
  local device_name="$1"
  log "DEBUG" "prepare_disk - device_name; $${device_name}"

  local device_mountpoint="$2"
  log "DEBUG" "prepare_disk - device_mountpoint; $${device_mountpoint}"

  local device_label="$3"
  log "DEBUG" "prepare_disk - device_label; $${device_label}"

  local ebs_volume_id=$(aws ec2 describe-volumes --filters Name=attachment.device,Values=$${device_name} Name=attachment.instance-id,Values=$INSTANCE_ID --query 'Volumes[*].{ID:VolumeId}' --region $REGION --output text | tr -d '-' )
  log "DEBUG" "prepare_disk - ebs_volume_id; $${ebs_volume_id}"

  local device_id=$(readlink -f /dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_$${ebs_volume_id})
  log "DEBUG" "prepare_disk - device_id; $${device_id}"

  mkdir $device_mountpoint

  # exclude quotes on device_label or formatting will fail
  mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0 -L $device_label $${device_id}

  echo "LABEL=$device_label $device_mountpoint ext4 defaults 0 2" >> /etc/fstab

  mount -a
}

main() {
  log "INFO" "Beginning custom_data script."
  OS_DISTRO=$(detect_os_distro)
  log "INFO" "Detected OS distro is '$OS_DISTRO'."

  log "INFO" "Scraping VM metadata required for Vault configuration"
  scrape_vm_info

  log "INFO" "Installing $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES"
  install_packages "$OS_DISTRO"

  log "INFO" "Installing AWS CLI"
  install_aws_cli "$OS_DISTRO"

  log "INFO" "Preparing Vault data disk"
  prepare_disk "/dev/sdf" "/opt/vault" "vault-data"

  log "INFO" "Preparing Vault audit logs disk"
  prepare_disk "/dev/sdg" "/var/log/vault" "vault-audit"

  log "INFO" "Creating Vault system user and group"
  user_group_create

  log "INFO" "Creating directories for Vault config and data"
  directory_create

  log "INFO" "Installing Vault"
  install_vault_binary

  log "INFO" "Installing Vault plugins"
  install_vault_plugins

  log "INFO" "Retrieving Vault license file from Secret Manager"
  fetch_vault_license

  log "INFO" "Retrieving Vault API TLS certificates from Secret Manager"
  fetch_tls_certificates

  log "INFO" "Generating Vault server configuration file"
  generate_vault_config

  log "INFO" "Generating Vault systemd unit file and overrides.conf"
  generate_vault_systemd_unit_file

  log "INFO" "Generating audit log rotation script"
  generate_vault_logrotate

  log "INFO" "Starting Vault"
  start_enable_vault

  log "INFO" "Configuring Vault CLI"
  configure_vault_cli

  exit_script 0
}

main "$@"