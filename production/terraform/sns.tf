resource "aws_sns_topic" "payment_events" {
  name = "fiap_sa_payment_service_payment_events"
}

resource "aws_sns_topic_subscription" "subscription" {
  topic_arn = aws_sns_topic.payment_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order_queue.arn
}
