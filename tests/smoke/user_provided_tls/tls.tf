module "etcd_certs" {
  source = "../../modules/tls/etcd/user-provided"

  etcd_ca_crt_pem_path     = "/path/to/etcd-ca.crt"
  etcd_server_crt_pem_path = "/path/to/etcd-server.crt"
  etcd_server_key_pem_path = "/path/to/etcd-server.key"
  etcd_peer_crt_pem_path   = "/path/to/etcd-peer.crt"
  etcd_peer_key_pem_path   = "/path/to/etcd-peer.key"
  etcd_client_crt_pem_path = "/path/to/etcd-client.crt"
  etcd_client_key_pem_path = "/path/to/etcd-client.key"
}

module "identity_certs" {
  source = "../../modules/tls/identity/user-provided"

  client_key_pem_path  = "/path/to/identity-client.key"
  client_cert_pem_path = "/path/to/identity-client.crt"
  server_key_pem_path  = "/path/to/identity-server.key"
  server_cert_pem_path = "/path/to/identity-server.crt"
}

module "ingress_certs" {
  source = "../../modules/tls/ingress/user-provided"

  ca_cert_pem_path = "/path/to/ca.crt"
  cert_pem_path    = "/path/to/ingress.crt"
  key_pem_path     = "/path/to/ingress.key"
}

module "kube_certs" {
  source = "../../modules/tls/kube/user-provided"

  ca_cert_pem_path        = "/path/to/ca.crt"
  kubelet_cert_pem_path   = "/path/to/kubelet.crt"
  kubelet_key_pem_path    = "/path/to/kubelet.key"
  apiserver_cert_pem_path = "/path/to/apiserver.crt"
  apiserver_key_pem_path  = "/path/to/apiserver.key"
}
