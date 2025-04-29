output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "EKS cluster API endpoint"
}

output "eks_cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "EKS cluster name"
}

output "mysql_order_db_endpoint" {
  value       = aws_db_instance.rds_mysql_order.endpoint
  description = "MySQL Order Database Endpoint"
}

output "mysql_product_db_endpoint" {
  value       = aws_db_instance.rds_mysql_product.endpoint
  description = "MySQL Product Database Endpoint"
}

output "load_balancer_url" {
  value       = aws_lb.http.dns_name
  description = "URL of the load balancer"
}
