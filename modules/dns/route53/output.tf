output "ingress_external_fqdn" {
  value = "${aws_route53_record.ingress-public.name}"
}

output "ingress_internal_fqdn" {
  value = "${aws_route53_record.ingress-private.name}"
}

output "api_external_fqdn" {
  value = "${aws_route53_record.api-external.name}"
}

output "api_internal_fqdn" {
  value = "${aws_route53_record.api-internal.name}"
}

# We have to do this join() & split() 'trick' because the ternary operator can't output lists.
#output "etcd_endpoints" {
#  value = ["${split(",", length(var.etcd_external_endpoints) == 0 ? join(",", aws_route53_record.etc_a_nodes.*.fqdn) : join(",", var.etcd_external_endpoints))}"]
#}

output "etcd_endpoints" {
  value = ["${aws_route53_record.etc_a_nodes.*.fqdn}"]
}
