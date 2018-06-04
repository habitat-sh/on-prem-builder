output "public_ips" {
  value = "${aws_instance.builder.public_ip}"
}
