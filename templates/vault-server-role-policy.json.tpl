{
  "Version": "2012-10-17",
  "Statement": [
    %{ if vault_license_secret != "" ~}
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "${vault_license_secret}"
    },
    %{ endif ~}
    %{ if vault_ca_bundle_secret != "" ~}
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "${vault_ca_bundle_secret}"
    },
    %{ endif ~}
    %{ if vault_signed_cert_secret != "" ~}
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "${vault_signed_cert_secret}"
    },
    %{ endif ~}
    %{ if vault_private_key_secret != "" ~}
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "${vault_private_key_secret}"
    },
    %{ endif ~}
    %{ if vault_seal_type == "awskms" ~}
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateRandom"
      ],
      "Resource": "${vault_kms_key_arn.arn}"
    },
    %{ endif ~}
    %{ if vault_snapshots_bucket_arn != "" ~}
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:ListBucketVersions"
      ],
      "Resource": [
        "${vault_snapshots_bucket_arn}",
        "${vault_snapshots_bucket_arn}/*"
      ]
    },
    %{ endif ~}
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeVolumes"
      ],
      "Resource": "*"
    }
  ]
}
