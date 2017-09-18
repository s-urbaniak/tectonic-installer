data "ignition_config" "main" {
  files = [
    "${var.ign_max_user_watches_id}",
    "${var.ign_s3_puller_id}",
    "${data.ignition_file.init_assets.id}",
    "${data.ignition_file.detect_master.id}",
    "${data.ignition_file.ca_cert_pem.*.id}",
  ]

  systemd = ["${compact(list(
    var.ign_docker_dropin_id,
    var.ign_locksmithd_service_id,
    var.ign_kubelet_service_id,
    var.ign_s3_kubelet_env_service_id,
    data.ignition_systemd_unit.init_assets.id,
    var.ign_bootkube_service_id,
    var.ign_tectonic_service_id,
    var.ign_bootkube_path_unit_id,
    var.ign_tectonic_path_unit_id,
    var.ign_update_ca_certificates_dropin_id,
   ))}"]
}

data "ignition_file" "detect_master" {
  filesystem = "root"
  path       = "/opt/detect-master.sh"
  mode       = 0755

  content {
    content = "${file("${path.module}/resources/detect-master.sh")}"
  }
}

data "template_file" "init_assets" {
  template = "${file("${path.module}/resources/init-assets.sh")}"

  vars {
    cluster_name       = "${var.cluster_name}"
    awscli_image       = "${var.container_images["awscli"]}"
    assets_s3_location = "${var.assets_s3_location}"
    kubelet_image_url  = "${replace(var.container_images["hyperkube"],var.image_re,"$1")}"
    kubelet_image_tag  = "${replace(var.container_images["hyperkube"],var.image_re,"$2")}"
  }
}

data "ignition_file" "init_assets" {
  filesystem = "root"
  path       = "/opt/init-assets.sh"
  mode       = 0755

  content {
    content = "${data.template_file.init_assets.rendered}"
  }
}

data "ignition_systemd_unit" "init_assets" {
  name    = "init-assets.service"
  enabled = "${var.assets_s3_location != "" ? true : false}"
  content = "${file("${path.module}/resources/services/init-assets.service")}"
}

data "ignition_file" "ca_cert_pem" {
  count = "${var.ign_ca_cert_list_count}"

  filesystem = "root"
  path       = "/etc/ssl/certs/ca_${count.index}.pem"
  mode       = 0400
  uid        = 0
  gid        = 0

  source {
    source       = "${var.ign_ca_cert_s3_list[count.index]}"
    verification = "sha512-${sha512(var.ign_ca_cert_pem_list[count.index])}"
  }
}
