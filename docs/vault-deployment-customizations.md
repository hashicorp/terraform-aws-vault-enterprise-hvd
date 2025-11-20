# Deployment customizations

On this page are various deployment customizations and their corresponding input variables that you may set to meet your requirements.

## DNS

This module supports creating an _alias_ record in AWS Route53 for the Boundary FQDN to resolve to the Boundary API load balancer DNS name. To do so, the following module input variables may be set:

```hcl
create_route53_vault_dns_record      = <true>
route53_vault_hosted_zone_name       = "<example.com>"
route53_vault_hosted_zone_is_private = <false>
```

## Custom AMI

If you have a custom AWS AMI you would like to use, you can specify it via the following module input variables:

```hcl
vm_image_id    = "<custom-rhel-ami-id>"
ec2_os_distro = "<rhel>"
```



## Deployment troubleshooting

In the `compute.tf` there is a commented out local file resource that will render the Boundary custom data script to a local file where this module is being run. This can be useful for reviewing the custom data script as it will be rendered on the deployed VM. This fill will contain sensitive vaults so do not commit this and delete this file when done troubleshooting.

## Custom startup script

While this is not recommended, this module supports the ability to use your own custom startup script to install. `var.custom_startup_script_template` # defaults to /templates/vault_install.sh.tpl

- The script must exist in a folder named ./templates within your current working directory that you are running Terraform from.
- The script must contain all of the variables (denoted by ${example-variable}) in the module-level startup script
- *Use at your own peril*

By default, the script will attempt to install the required software dependencies.

> Note: if you use AL2023 ( amazon Linux) the template automatically switches from `gnupg2-minimal` to `gnupg2-full`
