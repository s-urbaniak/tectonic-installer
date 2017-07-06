module "etcd" {
  source       = "./etcd"
  base_domain  = "${var.tectonic_base_domain}"
  etcd_count   = "${var.tectonic_experimental ? 0 : min(var.tectonic_etcd_count, 1)}"
  cluster_name = "${var.tectonic_cluster_name}"
}

module "bootkube" {
  source         = "../../modules/bootkube"
  cloud_provider = ""

  kube_apiserver_url = "https://module.vnet.api_external_fqdn:443"
  oidc_issuer_url    = "https://module.vnet.ingress_internal_fqdn/identity"

  # Platform-independent variables wiring, do not modify.
  container_images = "${var.tectonic_container_images}"
  versions         = "${var.tectonic_versions}"

  ca_cert    = "${var.tectonic_ca_cert}"
  ca_key     = "${var.tectonic_ca_key}"
  ca_key_alg = "${var.tectonic_ca_key_alg}"

  service_cidr = "${var.tectonic_service_cidr}"
  cluster_cidr = "${var.tectonic_cluster_cidr}"

  advertise_address = "0.0.0.0"
  anonymous_auth    = "false"

  oidc_username_claim = "email"
  oidc_groups_claim   = "groups"
  oidc_client_id      = "tectonic-kubectl"

  etcd_endpoints      = ["${module.etcd.node_names}"]
  etcd_cert_dns_names = ["${module.etcd.node_names}"]
  etcd_ca_cert        = "${var.tectonic_etcd_ca_cert_path}"
  etcd_client_cert    = "${var.tectonic_etcd_client_cert_path}"
  etcd_client_key     = "${var.tectonic_etcd_client_key_path}"
  etcd_tls_enabled    = "${var.tectonic_etcd_tls_enabled}"

  experimental_enabled = "${var.tectonic_experimental}"

  master_count = "${var.tectonic_master_count}"
}
