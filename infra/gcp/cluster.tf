terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.28"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "jen" {
  name     = var.cluster_name
  location = var.region

  release_channel {
    channel = var.release_channel
  }

  networking_mode = "VPC_NATIVE"
  network         = var.network
  subnetwork      = var.subnetwork

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS", "APISERVER", "SCHEDULER", "CONTROLLER_MANAGER"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "APISERVER", "SCHEDULER", "CONTROLLER_MANAGER"]
  }

  ip_allocation_policy {}

  deletion_protection = false

  labels = {
    app = "jen"
    env = var.environment
  }
}

resource "google_container_node_pool" "default" {
  name       = "${var.cluster_name}-pool"
  location   = var.region
  cluster    = google_container_cluster.jen.name
  node_count = var.initial_node_count

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
    labels = {
      app = "jen"
      env = var.environment
    }
    tags = ["jen", "k8s"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "jen-staging"
}

variable "environment" {
  description = "Environment label (dev, staging, prod)"
  type        = string
  default     = "staging"
}

variable "initial_node_count" {
  description = "Initial node count for default pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Node machine type"
  type        = string
  default     = "e2-standard-4"
}

variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "network" {
  description = "VPC network name"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork name"
  type        = string
  default     = "default"
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.jen.name
}

output "endpoint" {
  description = "GKE control plane endpoint"
  value       = google_container_cluster.jen.endpoint
}

output "ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.jen.master_auth[0].cluster_ca_certificate
}