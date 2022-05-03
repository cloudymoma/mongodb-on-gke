variable "project_id" {
  default = ""
}

variable "cluster_name" {
  default = ""
}

variable "region" {
  default = ""
}

variable "cluster_domain" {
  default = ""
}

variable "tags" {
  default = "cluster-tags"
}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}

variable "machine_type" {
  default     = "n2-standard-8"
  description = "machine type of gke nodes"
}
