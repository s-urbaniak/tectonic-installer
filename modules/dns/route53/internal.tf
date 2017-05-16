resource "aws_route53_zone" "tectonic-int" {
  vpc_id        = "${var.vpc_id}"
  name          = "${var.base_domain}"
  force_destroy = true

  tags = "${merge(map(
      "Name", "${var.cluster_name}_tectonic_int_zone",
      "KubernetesCluster", "${var.cluster_name}"
    ), var.extra_tags)}"
}

resource "aws_route53_record" "api-internal" {
  zone_id = "${aws_route53_zone.tectonic-int.zone_id}"
  name    = "${var.custom_dns_name == "" ? var.cluster_name : var.custom_dns_name}-api.${var.base_domain}"
  type    = "A"

  alias {
    name                   = "${var.elb_internal_api_dns_name}"
    zone_id                = "${var.elb_internal_api_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ingress-private" {
  zone_id = "${aws_route53_zone.tectonic-int.zone_id}"
  name    = "${var.custom_dns_name == "" ? var.cluster_name : var.custom_dns_name}.${var.base_domain}"
  type    = "A"

  alias {
    name                   = "${var.elb_ingress_dns_name}"
    zone_id                = "${var.elb_ingress_zone_id}"
    evaluate_target_health = true
  }
}
