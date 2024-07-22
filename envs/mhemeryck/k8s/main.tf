data "terraform_remote_state" "node" {
  backend = "local"
  config = {
    path = "../node/terraform.tfstate"
  }
}

module "k8s" {
  source = "../../../k8s"

  node_ip                = data.terraform_remote_state.node.outputs.ip
  client_certificate     = data.terraform_remote_state.node.outputs.kubecerts.client_certificate
  client_key             = data.terraform_remote_state.node.outputs.kubecerts.client_key
  cluster_ca_certificate = data.terraform_remote_state.node.outputs.kubecerts.cluster_ca_certificate
}
