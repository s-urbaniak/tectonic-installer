resource "local_file" "bootstrap_ign" {
  filename = "./generated/bootstrap.ign"
  content  = "${data.ignition_config.bootstrap.rendered}"
}

resource "local_file" "master_ign" {
  filename = "./generated/master.ign"
  content  = "${data.ignition_config.master.rendered}"
}

resource "local_file" "worker_ign" {
  filename = "./generated/worker.ign"
  content  = "${data.ignition_config.worker.rendered}"
}

resource "null_resource" "kubeconfig" {
  depends_on = ["module.bootkube"]

  connection {
    type    = "ssh"
    host    = "bootstrap.k8s"
    user    = "core"
    timeout = "60m"
  }

  provisioner "file" {
    content     = "${module.bootkube.kubeconfig}"
    destination = "$HOME/kubeconfig"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/core/kubeconfig /etc/kubernetes/kubeconfig",
    ]
  }
}

module "bootstrapper" {
  source = "../../modules/bootstrap-ssh"

  _dependencies = [
    "${module.bootkube.id}",
    "${module.tectonic.id}",
    "${local_file.master_ign.id}",
    "${local_file.worker_ign.id}",
  ]

  bootstrapping_host = "bootstrap.k8s"
}
