# Automatic Provisioning for On Premise Builder

On-prem-builder is currently only supported for single node deployment. This provisioner aims to make deploying on-prem-builder automated. Ultimately, the goal is to discover platforms and provisioning methods that customers are using and provide strong, happy-path automated provisioning for these methods. For customers that need to stray outside of these methods, this can provide a strong blueprint to get started and to customize their own provisioning methods.

## Support

Support for automated provisioning for on-prem-builder is experimental. Use at your own risk. No support of any kind is guarenteed at this time.

## Usage

Deploy using Terraform and store your state file in secure storage, like an S3 bucket. Use of a CI pipeline to execute is highly recommeneded.

1. Create a terraform.tfvars in the same directory as main.tf, and fill it out using the variables described in inputs.tf.
1. `terraform init`
1. `terraform plan`
1. `terraform apply`

## Troubleshooting
