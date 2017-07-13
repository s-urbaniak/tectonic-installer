output "ips" {
  value = ["${digitalocean_droplet.master_node.*.ipv4_address}"]
}
