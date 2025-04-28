variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster and prefix for all related resources"
  type        = string
  default     = "fiap-restaurant"
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role with EKS cluster permissions (required)"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for EKS worker nodes (required)"
  type        = string
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
