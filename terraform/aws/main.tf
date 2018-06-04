terraform {
  // Always hard pin, Terraform frequently introduces breaking changes in minor/patch versions.
  required_version = "0.11.7"
}

provider "aws" {
  profile                 = "${var.aws_profile}"
  shared_credentials_file = "~/.aws/credentials"
  region                  = "${var.aws_region}"
}

resource "random_id" "hash" {
  byte_length = 4
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name          = "${var.tag_customer}_${var.tag_project}_${var.tag_application}_${random_id.hash.hex}"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name          = "${var.tag_customer}_${var.tag_project}_${var.tag_application}_${random_id.hash.hex}"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags {
    Name          = "${var.tag_customer}_${var.tag_project}_${var.tag_application}_${random_id.hash.hex}"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }
}

////////////////////////////////
// Firewalls

resource "aws_security_group" "default" {
  name        = "${var.tag_application}"
  description = "${var.tag_application}"
  vpc_id      = "${aws_vpc.default.id}"

  tags {
    Name          = "${var.tag_customer}_${var.tag_project}_${var.tag_application}_${random_id.hash.hex}"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
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

////////////////////////////////
// On Prem Builder - Single Instance

data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "name"
    values = ["chef-highperf-centos7-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["446539779517"]
}

resource "aws_instance" "builder" {
  connection {
    user        = "${var.aws_image_user}"
    private_key = "${file("${var.aws_key_pair_file}")}"
  }

  ami                         = "${data.aws_ami.centos.id}"
  instance_type               = "c4.xlarge"                          // Test: c4.xlarge Prod: c4.4xlarge
  key_name                    = "${var.aws_key_pair_name}"
  subnet_id                   = "${aws_subnet.default.id}"
  vpc_security_group_ids      = ["${aws_security_group.default.id}"]
  associate_public_ip_address = true

  root_block_device {
    delete_on_termination = true
    volume_size           = 100
    volume_type           = "gp2"
  }

  tags {
    Name          = "${var.tag_customer}_${var.tag_project}_${var.tag_application}_${random_id.hash.hex}"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
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
    source      = "${path.module}/../../install.sh"
    destination = "/home/${var.aws_image_user}/builder/install.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../uninstall.sh"
    destination = "/home/${var.aws_image_user}/builder/uninstall.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../ssl-certificate.key"
    destination = "/home/${var.aws_image_user}/builder/ssl-certificate.key"
  }

  provisioner "file" {
    source      = "${path.module}/../../ssl-certificate.crt"
    destination = "/home/${var.aws_image_user}/builder/ssl-certificate.crt"
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/hab-sup.service.sh"
    destination = "/home/${var.aws_image_user}/builder/scripts/hab-sup.service.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/install-hab.sh"
    destination = "/home/${var.aws_image_user}/builder/scripts/install-hab.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/on-prem-archive.sh"
    destination = "/home/${var.aws_image_user}/builder/scripts/on-prem-archive.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/provision.sh"
    destination = "/home/${var.aws_image_user}/builder/scripts/provision.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../bldr.env"
    destination = "/home/${var.aws_image_user}/builder/bldr.env"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/${var.aws_image_user}/builder/scripts",
      "chmod +x ./install-hab.sh ./hab-sup.service.sh ./provision.sh",
      "sudo -E ./install-hab.sh",
      "sudo -E ./hab-sup.service.sh",
      "sudo -E ./provision.sh",
    ]
  }
}
