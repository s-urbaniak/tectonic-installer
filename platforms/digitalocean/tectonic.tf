module "bootkube" {
  source = "../../modules/bootkube"

  cloud_provider     = ""
  kube_apiserver_url = "https://${var.tectonic_cluster_name}-api.${var.tectonic_base_domain}:443"
  oidc_issuer_url    = "https://${var.tectonic_cluster_name}.${var.tectonic_base_domain}:443/identity"

  # Platform-independent variables wiring, do not modify.
  advertise_address    = "0.0.0.0"
  anonymous_auth       = "false"
  ca_cert              = "${var.tectonic_ca_cert}"
  ca_key               = "${var.tectonic_ca_key}"
  ca_key_alg           = "${var.tectonic_ca_key_alg}"
  cluster_cidr         = "${var.tectonic_cluster_cidr}"
  container_images     = "${var.tectonic_container_images}"
  etcd_ca_cert         = "${var.tectonic_etcd_ca_cert_path}"
  etcd_client_cert     = "${var.tectonic_etcd_client_cert_path}"
  etcd_client_key      = "${var.tectonic_etcd_client_key_path}"
  etcd_endpoints       = ["${module.etcd.endpoints}"]
  etcd_tls_enabled     = "${var.tectonic_etcd_tls_enabled}"
  experimental_enabled = "${var.tectonic_experimental}"
  master_count         = "${var.tectonic_master_count}"
  oidc_client_id       = "tectonic-kubectl"
  oidc_groups_claim    = "groups"
  oidc_username_claim  = "email"
  service_cidr         = "${var.tectonic_service_cidr}"
  versions             = "${var.tectonic_versions}"

  etcd_cert_dns_names = [
    "${var.tectonic_cluster_name}-etcd-0.${var.tectonic_base_domain}",
    "${var.tectonic_cluster_name}-etcd-1.${var.tectonic_base_domain}",
    "${var.tectonic_cluster_name}-etcd-2.${var.tectonic_base_domain}",
    "${var.tectonic_cluster_name}-etcd-3.${var.tectonic_base_domain}",
    "${var.tectonic_cluster_name}-etcd-4.${var.tectonic_base_domain}",
  ]
}

module "tectonic" {
  source = "../../modules/tectonic"

  base_address       = "${var.tectonic_cluster_name}.${var.tectonic_base_domain}"
  kube_apiserver_url = "https://${var.tectonic_cluster_name}-api.${var.tectonic_base_domain}:443"
  platform           = "digitalocean"

  # Platform-independent variables wiring, do not modify.
  admin_email         = "${var.tectonic_admin_email}"
  admin_password_hash = "${var.tectonic_admin_password_hash}"
  ca_cert             = "${module.bootkube.ca_cert}"
  ca_generated        = "${module.bootkube.ca_cert == "" ? false : true}"
  ca_key              = "${module.bootkube.ca_key}"
  ca_key_alg          = "${module.bootkube.ca_key_alg}"
  console_client_id   = "tectonic-console"
  container_images    = "${var.tectonic_container_images}"
  experimental        = "${var.tectonic_experimental}"
  ingress_kind        = "HostPort"
  kubectl_client_id   = "tectonic-kubectl"
  license_path        = "${pathexpand(var.tectonic_license_path)}"
  master_count        = "${var.tectonic_master_count}"
  pull_secret_path    = "${pathexpand(var.tectonic_pull_secret_path)}"
  stats_url           = "${var.tectonic_stats_url}"
  update_app_id       = "${var.tectonic_update_app_id}"
  update_channel      = "${var.tectonic_update_channel}"
  update_server       = "${var.tectonic_update_server}"
  versions            = "${var.tectonic_versions}"
}

data "archive_file" "assets" {
  type       = "zip"
  source_dir = "${path.cwd}/generated/"

  # Because the archive_file provider is a data source, depends_on can't be
  # used to guarantee that the tectonic/bootkube modules have generated
  # all the assets on disk before trying to archive them. Instead, we use their
  # ID outputs, that are only computed once the assets have actually been
  # written to disk. We re-hash the IDs (or dedicated module outputs, like module.bootkube.content_hash)
  # to make the filename shorter, since there is no security nor collision risk anyways.
  #
  # Additionally, data sources do not support managing any lifecycle whatsoever,
  # and therefore, the archive is never deleted. To avoid cluttering the module
  # folder, we write it in the TerraForm managed hidden folder `.terraform`.
  output_path = "${path.cwd}/.terraform/generated_${sha1("${module.tectonic.id} ${module.bootkube.id}")}.zip"
}

# Copy kubeconfig to master nodes
resource "null_resource" "master_nodes" {
  count = 1

  # Re-provision on changes to masters
  triggers {
    master_address = "${element(module.masters.ips, count.index)}"
  }

  connection {
    type    = "ssh"
    host    = "${element(module.masters.ips, count.index)}"
    user    = "core"
    timeout = "1m"
  }

  provisioner "file" {
    content     = "${module.bootkube.kubeconfig}"
    destination = "$HOME/kubeconfig"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv $HOME/kubeconfig /etc/kubernetes/",
    ]
  }
}

# Copy assets to first master node
resource "null_resource" "first_master" {
  # Re-provision on changes to first master node
  triggers {
    node_address = "${module.masters.ips[0]}"
  }

  connection {
    type    = "ssh"
    host    = "${module.masters.ips[0]}"
    user    = "core"
    timeout = "1m"
  }

  provisioner "file" {
    source      = "${data.archive_file.assets.output_path}"
    destination = "$HOME/tectonic.zip"
  }

  provisioner "file" {
    source      = "${path.root}/resources/bootstrap-first-master.sh"
    destination = "$HOME/bootstrap-first-master.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x $HOME/bootstrap-first-master.sh",
      "$HOME/bootstrap-first-master.sh ${var.tectonic_vanilla_k8s ? "" : "--enable-tectonic"}",
      "rm $HOME/bootstrap-first-master.sh",
    ]
  }
}

# Copy kubeconfig to worker nodes
resource "null_resource" "worker_nodes" {
  count = "${var.tectonic_worker_count}"

  # Re-provision on changes to workers
  triggers {
    node_address = "${element(module.workers.ips, count.index)}"
  }

  connection {
    type    = "ssh"
    host    = "${element(module.workers.ips, count.index)}"
    user    = "core"
    timeout = "1m"
  }

  provisioner "file" {
    content     = "${module.bootkube.kubeconfig}"
    destination = "$HOME/kubeconfig"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv $HOME/kubeconfig /etc/kubernetes/",
    ]
  }
}
