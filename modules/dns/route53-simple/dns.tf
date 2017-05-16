# tectonic

data "aws_route53_zone" "tectonic" {
  name = "${var.tectonic_base_domain}"
}

resource "aws_route53_record" "tectonic-api" {
  name    = "${var.tectonic_cluster_name}-k8s"
  records = ["${var.master_ips}"]
  ttl     = "60"
  type    = "A"
  zone_id = "${data.aws_route53_zone.tectonic.zone_id}"
}

resource "aws_route53_record" "tectonic-console" {
  name    = "${var.tectonic_cluster_name}"
  records = ["${var.worker_ips}"]
  ttl     = "60"
  type    = "A"
  zone_id = "${data.aws_route53_zone.tectonic.zone_id}"
}

# master/worker

resource "aws_route53_record" "master_nodes" {
  count   = "${var.tectonic_master_count}"
  name    = "${var.tectonic_cluster_name}-master-${count.index}"
  records = ["${var.master_ips[count.index]}"]
  ttl     = "60"
  type    = "A"
  zone_id = "${data.aws_route53_zone.tectonic.zone_id}"
}

resource "aws_route53_record" "worker_nodes" {
  count   = "${var.tectonic_worker_count}"
  name    = "${var.tectonic_cluster_name}-worker-${count.index}"
  records = ["${var.worker_ips[count.index]}"]
  ttl     = "60"
  type    = "A"
  zone_id = "${data.aws_route53_zone.tectonic.zone_id}"
}

# etcd

resource "aws_route53_record" "etcd_srv_discover" {
  count   = "${var.etcd_dns_enabled ? 1 : 0}"
  name    = "_etcd-server._tcp"
  records = ["${formatlist("0 0 2380 %s", aws_route53_record.etc_a_nodes.*.fqdn)}"]
  ttl     = "300"
  type    = "SRV"
  zone_id = "${data.aws_route53_zone.tectonic.zone_id}"
}

resource "aws_route53_record" "etcd_srv_client" {
  count   = "${var.etcd_dns_enabled ? 1 : 0}"
  name    = "_etcd-client._tcp"
  records = ["${formatlist("0 0 2379 %s", aws_route53_record.etc_a_nodes.*.fqdn)}"]
  ttl     = "60"
  type    = "SRV"
  zone_id = "${data.aws_route53_zone.tectonic.zone_id}"
}

resource "aws_route53_record" "etc_a_nodes" {
  count   = "${var.etcd_dns_enabled ? length(var.etcd_ips) : 0}"
  name    = "${var.tectonic_cluster_name}-etcd-${count.index}"
  records = ["${var.etcd_ips[count.index]}"]
  ttl     = "60"
  type    = "A"
  zone_id = "${data.aws_route53_zone.tectonic.zone_id}"
}
