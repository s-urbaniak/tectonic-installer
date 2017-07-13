data "ignition_config" "etcd" {
  count = "${var.droplet_count}"

  systemd = [
    "${data.ignition_systemd_unit.locksmithd.*.id[count.index]}",
    "${data.ignition_systemd_unit.etcd3.*.id[count.index]}",
    "${data.ignition_systemd_unit.etcd_unzip_tls.id}",
  ]

  files = [
    "${data.ignition_file.node_hostname.*.id[count.index]}",
    "${data.ignition_file.etcd_tls_zip.id}",
  ]
}

data "ignition_file" "node_hostname" {
  count      = "${var.droplet_count}"
  path       = "/etc/hostname"
  mode       = 0644
  filesystem = "root"

  content {
    content = "${var.cluster_name}-etcd-${count.index}.${var.cluster_domain}"
  }
}

data "ignition_file" "etcd_tls_zip" {
  path       = "/etc/ssl/etcd/tls.zip"
  mode       = 0400
  uid        = 0
  gid        = 0
  filesystem = "root"

  content {
    mime    = "application/octet-stream"
    content = "${var.tls_zip}"
  }
}

data "ignition_systemd_unit" "etcd_unzip_tls" {
  name    = "etcd-unzip-tls.service"
  enable  = true
  content = "${file("${path.module}/resources/etcd-unzip-tls.service")}"
}

data "template_file" "locksmithd" {
  count    = "${var.droplet_count}"
  template = "${file("${path.module}/resources/locksmithd.service")}"

  vars = {
    cluster_domain = "${var.cluster_domain}"
    env_ca_file    = "${var.tls_enabled ? "Environment=\"LOCKSMITHD_ETCD_CAFILE=/etc/ssl/etcd/ca.crt\"" : ""}"
    env_cert_file  = "${var.tls_enabled ? "Environment=\"LOCKSMITHD_ETCD_CERTFILE=/etc/ssl/etcd/client.crt\"" : ""}"
    env_key_file   = "${var.tls_enabled ? "Environment=\"LOCKSMITHD_ETCD_KEYFILE=/etc/ssl/etcd/client.key\"" : ""}"
    etcd_name      = "${var.cluster_name}-etcd-${count.index}"
    scheme         = "${var.tls_enabled ? "https" : "http"}"
  }
}

data "ignition_systemd_unit" "locksmithd" {
  count  = "${var.droplet_count}"
  name   = "locksmithd.service"
  enable = true

  dropin = [
    {
      content = "${data.template_file.locksmithd.*.rendered[count.index]}"
      name    = "40-etcd-lock.conf"
    },
  ]
}

data "template_file" "initial-cluster" {
  count = "${var.droplet_count}"

  template = "${file("${path.module}/resources/initial-cluster.tpl")}"

  vars = {
    scheme       = "${var.tls_enabled ? "https" : "http"}"
    etcd_name    = "${var.cluster_name}-etcd-${count.index}"
    etcd_address = "${var.cluster_name}-etcd-${count.index}.${var.cluster_domain}"
  }
}

data "template_file" "etcd-cluster-conf" {
  count = "${var.droplet_count}"

  template = "${file("${path.module}/resources/etcd-cluster.conf")}"

  vars = {
    cluster_domain  = "${var.cluster_domain}"
    container_image = "${var.container_image}"
    etcd_name       = "${var.cluster_name}-etcd-${count.index}"
    initial_cluster = "${join(",", data.template_file.initial-cluster.*.rendered)}"
    scheme          = "${var.tls_enabled ? "https" : "http"}"

    cert_args = "${var.tls_enabled
      ? "--cert-file=/etc/ssl/etcd/server.crt --key-file=/etc/ssl/etcd/server.key --peer-cert-file=/etc/ssl/etcd/peer.crt --peer-key-file=/etc/ssl/etcd/peer.key --peer-trusted-ca-file=/etc/ssl/etcd/ca.crt -peer-client-cert-auth=true"
      : ""}"
  }
}

data "ignition_systemd_unit" "etcd3" {
  count  = "${var.droplet_count}"
  name   = "etcd-member.service"
  enable = true

  dropin = [
    {
      content = "${data.template_file.etcd-cluster-conf.*.rendered[count.index]}"
      name    = "40-etcd-cluster.conf"
    },
  ]
}
