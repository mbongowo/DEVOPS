variable "cluster_name" {
  description = "Name of the local kind cluster"
  type        = string
  default     = "flask-cicd"
}

variable "node_image" {
  description = "kind node image (pins the Kubernetes version)"
  type        = string
  default     = "kindest/node:v1.31.2"
}

variable "http_host_port" {
  description = "Host port mapped to the ingress controller's HTTP port"
  type        = number
  default     = 8080
}

variable "https_host_port" {
  description = "Host port mapped to the ingress controller's HTTPS port"
  type        = number
  default     = 8443
}
