output "cluster_endpoint" {
  value = local.cluster_exists ? data.aws_eks_cluster.existing.endpoint : aws_eks_cluster.this[0].endpoint
}

output "cluster_name" {
  value = var.cluster_name
}

output "node_group_status" {
  value = local.node_group_exists ? "Existing node group found" : "New node group created"
}

output "rds_order_service_endpoint" {
  value = length(aws_db_instance.order_service_mysql) > 0 ? aws_db_instance.order_service_mysql[0].endpoint : null
}

output "rds_product_service_endpoint" {
  value = length(aws_db_instance.product_service_mysql) > 0 ? aws_db_instance.product_service_mysql[0].endpoint : null
}
