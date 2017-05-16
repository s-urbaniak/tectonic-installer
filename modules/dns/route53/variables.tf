variable "etcd_external_endpoints" {
  type = "list"
}

variable "etcd_ips" {
  type = "list"
}

variable "cluster_name" {
  type = "string"
}

variable "base_domain" {
  type = "string"
}

variable "vpc_public" {
  default = true
}

variable "elb_internal_api_dns_name" {
  type = "string"
}

variable "elb_internal_api_zone_id" {
  type = "string"
}

variable "elb_external_api_dns_name" {
  type = "string"
}

variable "elb_external_api_zone_id" {
  type = "string"
}

variable "elb_ingress_dns_name" {
  type = "string"
}

variable "elb_ingress_zone_id" {
  type = "string"
}

variable "custom_dns_name" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "extra_tags" {
  type    = "map"
  default = {}
}
