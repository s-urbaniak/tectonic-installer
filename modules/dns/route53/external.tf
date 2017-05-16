data "aws_route53_zone" "tectonic-ext" {
  count = "${var.vpc_public}"
  name  = "${var.base_domain}"
}

resource "aws_route53_record" "api-external" {
  count   = "${var.vpc_public}"
  zone_id = "${join("", data.aws_route53_zone.tectonic-ext.*.zone_id)}"
  name    = "${var.custom_dns_name == "" ? var.cluster_name : var.custom_dns_name}-api.${var.base_domain}"
  type    = "A"

  alias {
    name                   = "${var.elb_external_api_dns_name}"
    zone_id                = "${var.elb_external_api_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ingress-public" {
  count   = "${var.vpc_public}"
  zone_id = "${join("", data.aws_route53_zone.tectonic-ext.*.zone_id)}"
  name    = "${var.custom_dns_name == "" ? var.cluster_name : var.custom_dns_name}.${var.base_domain}"
  type    = "A"

  alias {
    name                   = "${var.elb_ingress_dns_name}"
    zone_id                = "${var.elb_ingress_zone_id}"
    evaluate_target_health = true
  }
}
