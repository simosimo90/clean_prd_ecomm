
#-Creating SQS queue
resource "aws_sqs_queue" "sqs_queue" {
  name                        = "api_req_queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}

# Connecting SQS to Lambda
resource "aws_lambda_event_source_mapping" "sqs_lambda" {
  event_source_arn = aws_sqs_queue.sqs_queue.arn
  function_name    = aws_lambda_function.order_services_lambda.function_name
  batch_size       = 10

  scaling_config {
    maximum_concurrency = 100
  }
}