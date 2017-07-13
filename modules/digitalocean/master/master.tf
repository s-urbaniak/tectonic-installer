resource "digitalocean_droplet" "master_node" {
  count     = "${var.instance_count}"
  name      = "${var.cluster_name}-master-${count.index}"
  image     = "${var.droplet_image}"
  region    = "${var.droplet_region}"
  size      = "${var.droplet_size}"
  ssh_keys  = ["${var.ssh_keys}"]
  tags      = ["${var.extra_tags}"]
  user_data = "${var.user_data}"
}

resource "digitalocean_record" "master" {
  count  = "${var.instance_count}"
  domain = "${var.cluster_domain}"
  name   = "${var.cluster_name}-master-${count.index}"
  ttl    = 60
  type   = "A"
  value  = "${element(digitalocean_droplet.master_node.*.ipv4_address, count.index)}"
}

resource "digitalocean_record" "tectonic-api" {
  count  = "${var.instance_count}"
  domain = "${var.cluster_domain}"
  name   = "${var.cluster_name}-api"
  ttl    = 60
  type   = "A"
  value  = "${element(digitalocean_droplet.master_node.*.ipv4_address, count.index)}"
}
