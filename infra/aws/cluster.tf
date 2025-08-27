terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

############################################################
# EKS IAM ROLES
############################################################

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume.json
  tags = {
    app = "jen"
    env = var.environment
  }
}

data "aws_iam_policy_document" "eks_cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role" "eks_node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume.json
  tags = {
    app = "jen"
    env = var.environment
  }
}

data "aws_iam_policy_document" "eks_node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

############################################################
# SECURITY GROUP (optional basic SG for the cluster)
############################################################

resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id
  tags = {
    Name = "${var.cluster_name}-cluster-sg"
    app  = "jen"
    env  = var.environment
  }
}

############################################################
# EKS CLUSTER
############################################################

resource "aws_eks_cluster" "jen" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    app = "jen"
    env = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSServicePolicy
  ]
}

############################################################
# MANAGED NODE GROUP
############################################################

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.jen.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = var.subnet_ids
  ami_type        = var.ami_type
  capacity_type   = var.capacity_type
  disk_size       = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired
    max_size     = var.node_max
    min_size     = var.node_min
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = [var.instance_type]

  tags = {
    app = "jen"
    env = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy
  ]
}

############################################################
# VARIABLES
############################################################

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI/SDK profile to use"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "jen-staging"
}

variable "environment" {
  description = "Environment label (dev, staging, prod)"
  type        = string
  default     = "staging"
}

variable "vpc_id" {
  description = "VPC ID for EKS"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs (private preferred)"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for cluster"
  type        = string
  default     = "1.29"
}

variable "endpoint_private_access" {
  description = "Enable private API endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API endpoint"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "Allowed CIDRs if public endpoint is enabled"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 instance type for nodes"
  type        = string
  default     = "m6i.large"
}

variable "node_min" {
  description = "Minimum node count"
  type        = number
  default     = 1
}

variable "node_desired" {
  description = "Desired node count"
  type        = number
  default     = 2
}

variable "node_max" {
  description = "Maximum node count"
  type        = number
  default     = 4
}

variable "ami_type" {
  description = "AMI type for EKS nodes"
  type        = string
  default     = "AL2_x86_64"
}

variable "capacity_type" {
  description = "ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "Node disk size in GiB"
  type        = number
  default     = 50
}

############################################################
# OUTPUTS
############################################################

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.jen.name
}

output "endpoint" {
  description = "EKS control plane endpoint"
  value       = aws_eks_cluster.jen.endpoint
}

output "ca_certificate" {
  description = "EKS cluster CA certificate (base64)"
  value       = aws_eks_cluster.jen.certificate_authority[0].data
}