variable "const_internal_node_names" {
  type        = "list"
  default     = ["etcd-0", "etcd-1", "etcd-2", "etcd-3", "etcd-4"]
  description = "(internal) The list of hostnames assigned to etcd member nodes."
}

variable "cluster_name" {
  type = "string"
}

variable "base_domain" {
  type = "string"
}

variable "etcd_count" {
  type = "string"
}

output "node_names" {
  value = ["${split(";", var.base_domain == "" ? 
    join(";", slice(formatlist("${var.cluster_name}-%s", var.const_internal_node_names), 0, var.etcd_count)) : 
    join(";", formatlist("%s.${var.base_domain}", slice(formatlist("${var.cluster_name}-%s", var.const_internal_node_names), 0, var.etcd_count))))
  }"]
}
