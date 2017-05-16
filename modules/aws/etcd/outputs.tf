output "private_ips" {
  value = ["${aws_instance.etcd_node.*.private_ip}"]
}
