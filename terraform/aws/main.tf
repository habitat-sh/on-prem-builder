resource "random_id" "hash" {
  byte_length = 4
}

////////////////////////////////
// Firewalls

resource "aws_security_group" "default" {
  name        = "${var.tag_application}"
  description = "${var.tag_application}"
  vpc_id      = "${var.depot_vpc_id}"

  tags {
    Name          = "${var.depot_tag_customer}_${var.depot_tag_project}_${var.tag_application}_${random_id.hash.hex}"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.depot_tag_customer}"
    X-Project     = "${var.depot_tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "builder" {
  connection {
    user        = "${var.aws_image_user}"
    private_key = "${file("${var.aws_key_pair_file}")}"
  }

  ami                         = "${var.bldr_ami}"
  instance_type               = "${var.instance_type}"               // Test: c4.xlarge Prod: c4.4xlarge
  key_name                    = "${var.aws_key_pair_name}"
  subnet_id                   = "${var.subnet_id}"
  vpc_security_group_ids      = ["${aws_security_group.default.id}"]
  associate_public_ip_address = true

  root_block_device {
    delete_on_termination = true
    volume_size           = 100
    volume_type           = "gp2"
  }

  tags {
    Name          = "${var.depot_tag_customer}_${var.depot_tag_project}_${var.tag_application}_${random_id.hash.hex}"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.depot_tag_customer}"
    X-Project     = "${var.depot_tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/${var.aws_image_user}/builder/scripts",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/files/install.sh"
    destination = "/home/${var.aws_image_user}/builder/install.sh"
  }

  provisioner "file" {
    source      = "${path.module}/files/uninstall.sh"
    destination = "/home/${var.aws_image_user}/builder/uninstall.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/hab-sup.service.sh"
    destination = "/home/${var.aws_image_user}/builder/scripts/hab-sup.service.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install-hab.sh"
    destination = "/home/${var.aws_image_user}/builder/scripts/install-hab.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/on-prem-archive.sh"
    destination = "/home/${var.aws_image_user}/builder/scripts/on-prem-archive.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/provision.sh"
    destination = "/home/${var.aws_image_user}/builder/scripts/provision.sh"
  }

  provisioner "file" {
    content     = "${var.bldr_env_data}"
    destination = "/home/${var.aws_image_user}/builder/bldr.env"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/${var.aws_image_user}/builder/scripts",
      "chmod +x ./install-hab.sh ./hab-sup.service.sh ./provision.sh",
      "sudo -E ./install-hab.sh",
      "sudo -E ./hab-sup.service.sh",
      "sleep 10",
      "sudo -E ./provision.sh",
    ]

    provisioner "file" {
      source      = "${path.module}/upstream.toml"
      destination = "/home/${var.aws_image_user}/builder/upstream.toml"
    }

    provisioner "remote-exec" {
      inline = [
        "sudo -E hab config apply builder-api.default $(date +%s) /home/${var.aws_image_user}/builder/upstream.toml",
      ]
    }
  }
}
