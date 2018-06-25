output "public_ips" {
  value = "${aws_instance.builder.public_ip}"
}

output "depot_instance_id" {
  value = "${aws_instance.builder.id}"
}
