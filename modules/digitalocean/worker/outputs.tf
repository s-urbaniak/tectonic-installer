output "ips" {
  value = ["${digitalocean_droplet.worker_node.*.ipv4_address}"]
}
