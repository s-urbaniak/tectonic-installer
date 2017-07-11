data "aws_region" "current" {
  current = true
}

resource "aws_s3_bucket" "tectonic" {
  # Buckets must start with a lower case name and are limited to 63 characters,
  # so we prepend the letter 'a' and use the md5 hex digest for the case of a long domain
  # leaving 29 chars for the cluster name.
  bucket = "a${var.tectonic_cluster_name}-${md5("${data.aws_region.current.name}-${var.tectonic_base_domain}")}"

  acl = "private"

  tags = "${merge(map(
      "Name", "${var.tectonic_cluster_name}-tectonic",
      "KubernetesCluster", "${var.tectonic_cluster_name}",
      "tectonicClusterID", "${module.tectonic.cluster_id}"
    ), var.tectonic_aws_extra_tags)}"
}

# Bootkube / Tectonic assets
resource "aws_s3_bucket_object" "tectonic_assets" {
  bucket = "${aws_s3_bucket.tectonic.bucket}"
  key    = "assets.zip"
  source = "${data.archive_file.assets.output_path}"
  acl    = "private"

  # To be on par with the current Tectonic installer, we only do server-side
  # encryption, using AES256. Eventually, we should start using KMS-based
  # client-side encryption.
  server_side_encryption = "AES256"

  tags = "${merge(map(
      "Name", "${var.tectonic_cluster_name}-tectonic-assets",
      "KubernetesCluster", "${var.tectonic_cluster_name}",
      "tectonicClusterID", "${module.tectonic.cluster_id}"
    ), var.tectonic_aws_extra_tags)}"
}

# kubeconfig
resource "aws_s3_bucket_object" "kubeconfig" {
  bucket  = "${aws_s3_bucket.tectonic.bucket}"
  key     = "kubeconfig"
  content = "${module.bootkube.kubeconfig}"
  acl     = "private"

  # The current Tectonic installer stores bits of the kubeconfig in KMS. As we
  # do not support KMS yet, we at least offload it to S3 for now. Eventually,
  # we should consider using KMS-based client-side encryption, or uploading it
  # to KMS.
  server_side_encryption = "AES256"

  tags = "${merge(map(
      "Name", "${var.tectonic_cluster_name}-kubeconfig",
      "KubernetesCluster", "${var.tectonic_cluster_name}",
      "tectonicClusterID", "${module.tectonic.cluster_id}"
    ), var.tectonic_aws_extra_tags)}"
}

# public Kube CA cert
resource "aws_s3_bucket_object" "kube_ca_cert_pem" {
  bucket  = "${aws_s3_bucket.tectonic.bucket}"
  key     = "kube_ca.pem"
  content = "${module.kube_certs.ca_cert_pem}"
  acl     = "private"

  server_side_encryption = "AES256"

  tags = "${merge(map(
      "Name", "${var.tectonic_cluster_name}-kube-ca",
      "KubernetesCluster", "${var.tectonic_cluster_name}",
      "tectonicClusterID", "${module.tectonic.cluster_id}"
    ), var.tectonic_aws_extra_tags)}"
}

# custom CA certs
resource "aws_s3_bucket_object" "custom_ca_cert_pem" {
  count = "${length(var.tectonic_custom_ca_pem_list)}"

  bucket  = "${aws_s3_bucket.tectonic.bucket}"
  key     = "custom_ca_${count.index}.pem"
  content = "${var.tectonic_custom_ca_pem_list[count.index]}"
  acl     = "private"

  server_side_encryption = "AES256"

  tags = "${merge(map(
      "Name", "${var.tectonic_cluster_name}-custom-ca-${count.index}",
      "KubernetesCluster", "${var.tectonic_cluster_name}",
      "tectonicClusterID", "${module.tectonic.cluster_id}"
    ), var.tectonic_aws_extra_tags)}"
}
