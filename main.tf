terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.19.0"
    }
  }
}

provider "google" {
}

provider "google-beta" {
}

variable "project_id" {
  default = ""
}

variable "region" {
  default = ""
}

variable "cluster_name" {
  default = "gke-cluster"
}

variable "cluster_domain" {
  default = ""
}

variable "machine_type" {
  default = "e2-standard-4"
}

// Note: This is the number of gameserver nodes. The Agones module will automatically create an additional
// two node pools with 1 node each for "agones-system" and "agones-metrics".
variable "node_count" {
  default = "4"
}
variable "zone" {
  default     = "us-west1-c"
  description = "The GCP zone to create the cluster in"
}

variable "network" {
  default     = "default"
  description = "The name of the VPC network to attach the cluster and firewall rule to"
}

variable "subnetwork" {
  default     = ""
  description = "The subnetwork to host the cluster in. Required field if network value isn't 'default'."
}

variable "log_level" {
  default = "info"
}

variable "feature_gates" {
  default = ""
}

module "gke_cluster" {
  source         = "./modules/gke"
  cluster_name   = var.cluster_name
  project_id     = var.project_id
  region         = var.region
  cluster_domain = var.cluster_domain
  machine_type   = var.machine_type
}

output "host" {
  value = module.gke_cluster.host
}
#output "token" {
#  value = module.gke_cluster.token
#}
output "cluster_ca_certificate" {
  value = module.gke_cluster.cluster_ca_certificate
}
