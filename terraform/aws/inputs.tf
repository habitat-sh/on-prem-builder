variable "aws_region" {
  type        = "string"
  description = "The AWS region (datacenter) resources are created in."
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = "string"
  description = "The profile on disk. Typically stored in your ~/.aws/config file."
  default     = "egifter"
}

variable "aws_key_pair_file" {
  type        = "string"
  description = "The path on disk to your private key. This key will be used to establish connectivity to resources."
  
}

variable "aws_key_pair_name" {
  type        = "string"
  description = "The name in AWS associated with the public key on your AWS account. Used to allow access to your private key file by placing your public key on resources."
  default     = "egifter"
}

variable "aws_image_user" {
  type        = "string"
  description = "The user which will connect to resources."
  default     = "centos"
}

variable "tag_dept" {
  type        = "string"
  description = "X-Dept: A tag for identifying resources associated with your department."
  default     = "DevOps"
}

variable "depot_tag_customer" {
  type        = "string"
  description = "X-Customer: A tag for identifying resources associated with a customer."
}

variable "depot_tag_project" {
  type        = "string"
  description = "X-Project: A tag for identifying resources associated with a project."
}

variable "tag_application" {
  type        = "string"
  description = "X-Application: A tag for identifying resources associated with your application."
  default     = "Habitat Depot"
}

variable "tag_contact" {
  type        = "string"
  description = "X-Contact: A tag for identifying resources associated with your contact info. Use the form: my_name (myname@example.com)"
  default     = "admins@bluepipeline.io"
}

variable "tag_ttl" {
  type        = "string"
  description = "X-TTL: A tag for identifying time-to-live. Set for the number of hours until an instance is automatically destroyed. Set to 0 for never kill."
  default     = "Forever"
}

variable "subnet_id" {
  type        = "string"
  description = "Subnet ID"
}

variable "depot_vpc_id" {
  type        = "string"
  description = "VPC ID"
}

variable "instance_type" {
  type        = "string"
  description = "Depot Instance Size"
}

variable "os_filter_name" {
  type        = "string"
  description = "OS Search Name"
  default     = "indellient-bluepipeline-habitat-*"
}

variable "os_filter_account" {
  type        = "string"
  description = "OS Search Account"
  default     = "454860694652"
}

variable "bldr_env_data" {
  description = "The builder environment file data"
}
