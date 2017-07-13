resource "digitalocean_record" "etcd_nodes" {
  count  = "${var.droplet_count}"
  domain = "${var.cluster_domain}"
  name   = "${var.cluster_name}-etcd-${count.index}"
  ttl    = 60
  type   = "A"
  value  = "${digitalocean_droplet.etcd_node.*.ipv4_address[count.index]}"
}
