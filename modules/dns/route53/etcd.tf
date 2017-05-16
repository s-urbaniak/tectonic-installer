resource "aws_route53_record" "etcd_srv_discover" {
  count   = "${length(var.etcd_ips) == 0 ? 0 : 1}"
  name    = "_etcd-server._tcp"
  type    = "SRV"
  zone_id = "${aws_route53_zone.tectonic-int.zone_id}"
  records = ["${formatlist("0 0 2380 %s", aws_route53_record.etc_a_nodes.*.fqdn)}"]
  ttl     = "300"
}

resource "aws_route53_record" "etcd_srv_client" {
  count   = "${length(var.etcd_ips) == 0 ? 0 : 1}"
  name    = "_etcd-client._tcp"
  type    = "SRV"
  zone_id = "${aws_route53_zone.tectonic-int.zone_id}"
  records = ["${formatlist("0 0 2379 %s", aws_route53_record.etc_a_nodes.*.fqdn)}"]
  ttl     = "60"
}

resource "aws_route53_record" "etc_a_nodes" {
  count   = "${length(var.etcd_ips)}"
  type    = "A"
  ttl     = "60"
  zone_id = "${aws_route53_zone.tectonic-int.zone_id}"
  name    = "${var.cluster_name}-etcd-${count.index}"
  records = ["${var.etcd_ips[count.index]}"]
}
