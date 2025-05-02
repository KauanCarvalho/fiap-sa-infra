variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "lab_role" {
  description = "IAM role for the lab"
  type        = string
}

variable "node_group" {
  description = "Node group name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the EKS nodes"
  type        = string
}

variable "principal_arn" {
  description = "IAM role for the EKS cluster"
  type        = string
}

variable "policy_arn" {
  description = "IAM policy for the EKS cluster"
  type        = string
  default     = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}

variable "mysql_order_db_name" {
  description = "Name of the MySQL database for order service"
  type        = string
  sensitive   = true
}

variable "mysql_order_db_username" {
  description = "Master username for order service database"
  type        = string
  sensitive   = true
}

variable "mysql_order_db_password" {
  description = "Master password for order service database"
  type        = string
  sensitive   = true
}

variable "mysql_product_db_name" {
  description = "Name of the MySQL database for product service"
  type        = string
  sensitive   = true
}

variable "mysql_product_db_username" {
  description = "Master username for product service database"
  type        = string
  sensitive   = true
}

variable "mysql_product_db_password" {
  description = "Master password for product service database"
  type        = string
  sensitive   = true
}
