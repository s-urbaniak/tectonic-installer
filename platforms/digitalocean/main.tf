provider "digitalocean" {
  token = "${var.tectonic_do_token}"
}

module "etcd" {
  source = "../../modules/digitalocean/etcd"

  cluster_domain  = "${var.tectonic_base_domain}"
  cluster_name    = "${var.tectonic_cluster_name}"
  container_image = "${var.tectonic_container_images["etcd"]}"
  droplet_count   = "${var.tectonic_etcd_count > 0 ? var.tectonic_etcd_count : 1}"
  droplet_image   = "${var.tectonic_do_droplet_image}"
  droplet_image   = "${var.tectonic_do_droplet_image}"
  droplet_region  = "${var.tectonic_do_droplet_region}"
  droplet_region  = "${var.tectonic_do_droplet_region}"
  droplet_size    = "${var.tectonic_do_etcd_droplet_size}"
  extra_tags      = ["${var.tectonic_do_extra_tags}"]
  ssh_keys        = "${var.tectonic_do_ssh_keys}"
  swap_size       = "${var.tectonic_do_etcd_swap}"
  tls_enabled     = "${var.tectonic_etcd_tls_enabled}"
  tls_zip         = "${module.bootkube.etcd_tls_zip}"
}

module "ignition-masters" {
  source = "../../modules/digitalocean/ignition"

  bootkube_service          = "${module.bootkube.systemd_service}"
  cluster_domain            = "${var.tectonic_base_domain}"
  container_images          = "${var.tectonic_container_images}"
  kube_dns_service_ip       = "${module.bootkube.kube_dns_service_ip}"
  kubelet_node_label        = "node-role.kubernetes.io/master"
  kubelet_node_taints       = "node-role.kubernetes.io/master=:NoSchedule"
  swap_size                 = "${var.tectonic_do_master_swap}"
  tectonic_service          = "${module.tectonic.systemd_service}"
  tectonic_service_disabled = "${var.tectonic_vanilla_k8s}"
}

module "masters" {
  source = "../../modules/digitalocean/master"

  cluster_domain = "${var.tectonic_base_domain}"
  cluster_name   = "${var.tectonic_cluster_name}"
  droplet_image  = "${var.tectonic_do_droplet_image}"
  droplet_region = "${var.tectonic_do_droplet_region}"
  droplet_size   = "${var.tectonic_do_master_droplet_size}"
  extra_tags     = ["${var.tectonic_do_extra_tags}"]
  instance_count = "${var.tectonic_master_count}"
  ssh_keys       = "${var.tectonic_do_ssh_keys}"
  user_data      = "${module.ignition-masters.ignition}"
}

module "ignition-workers" {
  source = "../../modules/digitalocean/ignition"

  bootkube_service    = ""
  cluster_domain      = "${var.tectonic_base_domain}"
  container_images    = "${var.tectonic_container_images}"
  kube_dns_service_ip = "${module.bootkube.kube_dns_service_ip}"
  kubelet_node_label  = "node-role.kubernetes.io/node"
  kubelet_node_taints = ""
  swap_size           = "${var.tectonic_do_worker_swap}"
}

module "workers" {
  source = "../../modules/digitalocean/worker"

  cluster_domain = "${var.tectonic_base_domain}"
  cluster_name   = "${var.tectonic_cluster_name}"
  droplet_image  = "${var.tectonic_do_droplet_image}"
  droplet_region = "${var.tectonic_do_droplet_region}"
  droplet_size   = "${var.tectonic_do_worker_droplet_size}"
  extra_tags     = ["${var.tectonic_do_extra_tags}"]
  instance_count = "${var.tectonic_worker_count}"
  ssh_keys       = "${var.tectonic_do_ssh_keys}"
  user_data      = "${module.ignition-workers.ignition}"
}
