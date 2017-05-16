output "elb_internal_api_dns_name" {
  value = "${aws_elb.api-internal.dns_name}"
}

output "elb_internal_api_zone_id" {
  value = "${aws_elb.api-internal.zone_id}"
}

output "elb_external_api_dns_name" {
  value = "${aws_elb.api-external.dns_name}"
}

output "elb_external_api_zone_id" {
  value = "${aws_elb.api-external.zone_id}"
}

output "elb_ingress_dns_name" {
  value = "${aws_elb.console.dns_name}"
}

output "elb_ingress_zone_id" {
  value = "${aws_elb.console.zone_id}"
}
