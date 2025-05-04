output "mysql_order_db_name" {
  value     = var.mysql_order_db_name
  sensitive = true
}

output "mysql_order_db_username" {
  value     = var.mysql_order_db_username
  sensitive = true
}

output "mysql_order_db_password" {
  value     = var.mysql_order_db_password
  sensitive = true
}

output "mysql_product_db_name" {
  value     = var.mysql_product_db_name
  sensitive = true
}

output "mysql_product_db_username" {
  value     = var.mysql_product_db_username
  sensitive = true
}

output "mysql_product_db_password" {
  value     = var.mysql_product_db_password
  sensitive = true
}

output "sns_topic_arn" {
  value = aws_sns_topic.payment_events.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.order_queue.id
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.order_queue.arn
}
