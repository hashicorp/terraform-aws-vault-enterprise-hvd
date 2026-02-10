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
# VAULT_INSTALL_URL="$${vault_install_url}"
PRODUCT="vault"
VAULT_VERSION="${vault_version}"
VERSION=$VAULT_VERSION
REQUIRED_PACKAGES="unzip"
ADDITIONAL_PACKAGES="${additional_package_names}"
AWS_REGION="${aws_region}"

function log {
  local level="$1"
  local message="$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local log_entry="$timestamp [$level] - $message"

  echo "$log_entry" | tee -a "$LOGFILE"

}

function detect_architecture {
  local ARCHITECTURE=""
  local OS_ARCH_DETECTED=$(uname -m)

  case "$OS_ARCH_DETECTED" in
    "x86_64"*)
      ARCHITECTURE="linux_amd64"
      ;;
    "aarch64"*)
      ARCHITECTURE="linux_arm64"
      ;;
    "arm"*)
      ARCHITECTURE="linux_arm"
      ;;
    *)
      log "ERROR" "Unsupported architecture detected: '$OS_ARCH_DETECTED'. "
      exit_script 1
      ;;
  esac

  echo "$ARCHITECTURE"

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
  elif [[ "$os_distro" == "centos" || "$os_distro" == "rhel" ]]; then
    yum install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
  elif [[  "$os_distro" == "amzn2023" ]]; then
    yum install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
    log "INFO" "Enabling gnupg2-full for Amazon Linux 2023."
    dnf swap gnupg2-minimal gnupg2-full -y
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

function checksum_verify {
  local os_arch="$1"

  # https://www.hashicorp.com/en/trust/security
  # checksum_verify downloads the $$PRODUCT binary and verifies its integrity
  log "INFO" "Verifying the integrity of the $${PRODUCT} binary."
  export GNUPGHOME=./.gnupg
  log "INFO" "Importing HashiCorp GPG key."
  sudo curl -s https://www.hashicorp.com/.well-known/pgp-key.txt | gpg --import

  log "INFO" "Downloading $${PRODUCT} binary"
  sudo curl -Os https://releases.hashicorp.com/"$${PRODUCT}"/"$${VERSION}"/"$${PRODUCT}"_"$${VERSION}"_"$${OS_ARCH}".zip
  log "INFO" "Downloading Vault Enterprise binary checksum files"
  sudo curl -Os https://releases.hashicorp.com/"$${PRODUCT}"/"$${VERSION}"/"$${PRODUCT}"_"$${VERSION}"_SHA256SUMS
  log "INFO" "Downloading Vault Enterprise binary checksum signature file"
  sudo curl -Os https://releases.hashicorp.com/"$${PRODUCT}"/"$${VERSION}"/"$${PRODUCT}"_"$${VERSION}"_SHA256SUMS.sig
  log "INFO" "Verifying the signature file is untampered."
  gpg --verify "$${PRODUCT}"_"$${VERSION}"_SHA256SUMS.sig "$${PRODUCT}"_"$${VERSION}"_SHA256SUMS
  if [[ $? -ne 0 ]]; then
    log "ERROR" "Gpg verification failed for SHA256SUMS."
    exit_script 1
  fi
  if [ -x "$(command -v sha256sum)" ]; then
    log "INFO" "Using sha256sum to verify the checksum of the $${PRODUCT} binary."
    sha256sum -c "$${PRODUCT}"_"$${VERSION}"_SHA256SUMS --ignore-missing
  else
    log "INFO" "Using shasum to verify the checksum of the $${PRODUCT} binary."
    shasum -a 256 -c "$${PRODUCT}"_"$${VERSION}"_SHA256SUMS --ignore-missing
	fi
  if [[ $? -ne 0 ]]; then
    log "ERROR" "Checksum verification failed for the $${PRODUCT} binary."
    exit_script 1
  fi
  log "INFO" "Checksum verification passed for the $${PRODUCT} binary."

  log "INFO" "Removing the downloaded files to clean up"
  sudo rm -f "$${PRODUCT}"_"$${VERSION}"_SHA256SUMS "$${PRODUCT}"_"$${VERSION}"_SHA256SUMS.sig
}

# install_vault_binary downloads the Vault binary and puts it in dedicated bin directory
function install_vault_binary {
  local os_arch="$1"
  log "INFO" "Deploying Vault Enterprise binary to $VAULT_DIR_BIN unzip and set permissions"
  sudo unzip "$${PRODUCT}"_"$${VAULT_VERSION}"_"$${OS_ARCH}".zip  vault -d $VAULT_DIR_BIN
  sudo unzip "$${PRODUCT}"_"$${VAULT_VERSION}"_"$${OS_ARCH}".zip -x vault -d $VAULT_DIR_LICENSE
  sudo rm -f "$${PRODUCT}"_"$${VAULT_VERSION}"_"$${OS_ARCH}".zip

	# Set the permissions for the Vault binary
  sudo chmod 0755 $VAULT_DIR_BIN/vault
  sudo chown $VAULT_USER:$VAULT_GROUP $VAULT_DIR_BIN/vault

	# Create a symlink to the Vault binary in /usr/local/bin
  sudo ln -sf $VAULT_DIR_BIN/vault /usr/local/bin/vault

  log "INFO" "Vault binary installed successfully at $VAULT_DIR_BIN/vault"
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



function retrieve_certs_from_awssm {
  local SECRET_ARN="$1"
  local DESTINATION_PATH="$2"
  local SECRET_REGION=$AWS_REGION
  local CERT_DATA
  local DECODED_DATA

  if [[ -z "$SECRET_ARN" ]]; then
    log "ERROR" "Secret ARN cannot be empty. Exiting."
    exit_script 5
  elif [[ "$SECRET_ARN" == arn:aws:secretsmanager:* ]]; then
    log "INFO" "Retrieving value of secret '$SECRET_ARN' from AWS Secrets Manager."
    CERT_DATA=$(aws secretsmanager get-secret-value --region $SECRET_REGION --secret-id $SECRET_ARN --query SecretString --output text)

    # Check if CERT_DATA is base64 encoded by attempting to decode
    if DECODED_DATA=$(echo "$CERT_DATA" | base64 -d 2>/dev/null); then
      log "INFO" "Successfully decoded base64 encoded data. Writing to $DESTINATION_PATH."
      echo "$DECODED_DATA" > $DESTINATION_PATH
    else
      log "WARNING" "Data does not appear to be base64 encoded. Writing as-is to $DESTINATION_PATH."
      echo "$CERT_DATA" > $DESTINATION_PATH
    fi
  else
    log "WARNING" "Did not detect AWS Secrets Manager secret ARN. Setting value of secret to what was passed in."
    CERT_DATA="$SECRET_ARN"

    # Check if CERT_DATA is base64 encoded by attempting to decode
    if DECODED_DATA=$(echo "$CERT_DATA" | base64 -d 2>/dev/null); then
      log "INFO" "Successfully decoded base64 encoded data. Writing to $DESTINATION_PATH."
      echo "$DECODED_DATA" > $DESTINATION_PATH
    else
      log "INFO" "Data does not appear to be base64 encoded. Writing as-is to $DESTINATION_PATH."
      echo "$CERT_DATA" > $DESTINATION_PATH
    fi
  fi
	# Validate that the certificate file was created and is not empty
	if [[ ! -s "$DESTINATION_PATH" ]]; then
	  log "ERROR" "Certificate file '$DESTINATION_PATH' is empty or missing after retrieval. Aborting."
	  exit_script 6
	fi

	# Basic sanity check for PEM-formatted data
	if ! grep -q "\-\-\-\-\-BEGIN " "$DESTINATION_PATH"; then
	  log "ERROR" "Certificate file '$DESTINATION_PATH' does not appear to contain PEM-formatted data. Aborting."
	  exit_script 7
	fi
  log "INFO" "Setting certificate file permissions and ownership"
  sudo chown $VAULT_USER:$VAULT_GROUP $DESTINATION_PATH
  sudo chmod 400 $DESTINATION_PATH

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
  path                   = "$VAULT_DIR_DATA"
  node_id                = "$INSTANCE_ID"
  performance_multiplier = ${vault_raft_performance_multiplier}

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
%{ if length(vault_telemetry_config) > 0 ~}
telemetry {
%{ for key, value in vault_telemetry_config ~}
  ${key} = "${value}"
%{ endfor ~}
}
%{ endif ~}
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

function exit_script {
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

  # add sleep in to wait longer for the disk attachment

  sleep 20

  local ebs_volume_id=$(aws ec2 describe-volumes --filters Name=attachment.device,Values=$${device_name} Name=attachment.instance-id,Values=$INSTANCE_ID --query 'Volumes[*].{ID:VolumeId}' --region $REGION --output text | tr -d '-' )
  if [[ -z "$${ebs_volume_id}" ]]; then
    log "ERROR" "No EBS volume found attached to device $${device_name}"
    exit_script 1
  fi
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
	OS_ARCH=$(detect_architecture)
	log "INFO" "Detected system architecture is '$OS_ARCH'."
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

  log "INFO" "Verifying checksum function"
  checksum_verify $OS_ARCH

  log "INFO" "Installing Vault"
  install_vault_binary $OS_ARCH

  log "INFO" "Installing Vault plugins"
  install_vault_plugins

  log "INFO" "Retrieving Vault license file from Secret Manager"
  fetch_vault_license

  log "INFO" "Retrieving Vault API TLS certificates from Secret Manager"
  retrieve_certs_from_awssm "${sm_vault_tls_cert_arn}" "$VAULT_DIR_TLS/cert.pem"
  retrieve_certs_from_awssm "${sm_vault_tls_cert_key_arn}" "$VAULT_DIR_TLS/key.pem"
  %{ if sm_vault_tls_ca_bundle != "NONE" ~}
  retrieve_certs_from_awssm "${sm_vault_tls_ca_bundle}" "$VAULT_DIR_TLS/ca.pem"
  %{ endif ~}

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
