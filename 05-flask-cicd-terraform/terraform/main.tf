# Provisions a local, reproducible Kubernetes cluster with kind. The same module
# shape (a cluster resource + outputs consumed by Helm) maps onto a managed
# cluster in the cloud — see the README for the terraform-aws-modules/eks variant.

resource "kind_cluster" "this" {
  name           = var.cluster_name
  node_image     = var.node_image
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      # Label the node so the ingress-nginx controller schedules here.
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = var.http_host_port
      }
      extra_port_mappings {
        container_port = 443
        host_port      = var.https_host_port
      }
    }

    node {
      role = "worker"
    }
  }
}
