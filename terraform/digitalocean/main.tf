provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_droplet" "builder" {
  image  = "${var.do_image}"
  name   = "builder-1"
  region = "${var.do_region}"
  size   = "${var.do_size}"
  monitoring = true
  ssh_keys = "${var.do_ssh_keys}"

  connection {
    host = "${digitalocean_droplet.builder.ipv4_address}"
    type = "ssh"
    user = "${var.do_ssh_user}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/${var.do_ssh_user}/builder/scripts",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../../install.sh"
    destination = "/home/${var.do_ssh_user}/builder/install.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../uninstall.sh"
    destination = "/home/${var.do_ssh_user}/builder/uninstall.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../ssl-certificate.key"
    destination = "/home/${var.do_ssh_user}/builder/ssl-certificate.key"
  }

  provisioner "file" {
    source      = "${path.module}/../../ssl-certificate.crt"
    destination = "/home/${var.do_ssh_user}/builder/ssl-certificate.crt"
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/hab-sup.service.sh"
    destination = "/home/${var.do_ssh_user}/builder/scripts/hab-sup.service.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/install-hab.sh"
    destination = "/home/${var.do_ssh_user}/builder/scripts/install-hab.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/on-prem-archive.sh"
    destination = "/home/${var.do_ssh_user}/builder/scripts/on-prem-archive.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/provision.sh"
    destination = "/home/${var.do_ssh_user}/builder/scripts/provision.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../bldr.env"
    destination = "/home/${var.do_ssh_user}/builder/bldr.env"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/${var.do_ssh_user}/builder/scripts",
      "chmod +x ./install-hab.sh ./hab-sup.service.sh ./provision.sh",
      "sudo -E ./install-hab.sh",
      "sudo -E ./hab-sup.service.sh",
      "sudo -E ./provision.sh",
    ]
  }

}
