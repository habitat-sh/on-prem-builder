variable "do_token" {
  type = string
  description = "Your Digital Ocean Access Token"
}
variable "do_ssh_keys" {
  type = list(string)
  description = "Array of SSH Key IDs to be provisioned onto the droplet"
}

variable "do_image" {
  default = "47383149" # Ubuntu 19.04
  type = string
  description = "Image ID from Digital Oceans list of available droplet images"
}

variable "do_region" {
  default = "sfo2"
  type = string
  description = "Digital Ocean region ID"
}

variable "do_size" {
  default = "s-1vcpu-2gb"
  type = string
  description = "Size of the droplet to be deployed"
}

variable "do_ssh_user" {
  default = "root"
  type = string
  description = "User to SSH into the droplet with for provisioning purposes"
}
