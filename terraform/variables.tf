variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
  default     = "vpc-0e027ddb0953db549"
}

variable "public_subnet_ids" {
  description = "Existing public subnet IDs (must span at least 2 AZs)"
  type        = list(string)
  default     = ["subnet-0c89f10ca65a0f99e", "subnet-09fcbbb204c1888ad"]
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "pern-eks"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 2
}