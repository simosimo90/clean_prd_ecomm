# SNS topic whre the publisher is the downstream-lambda and the subscribers
# are the ddown stream services


resource "aws_sns_topic" "order_services_topic" {
  name = "order-services-topic"
}



# Example of a downstream service subscribing to the SNS topic.
# This is just an exemple as the entire architecture ddoees not include the downstream servicces
# but just asssume the existence of them

resource "aws_sns_topic_subscription" "down_service1_sub" {
  topic_arn = aws_sns_topic.order_services_topic.arn
  protocol  = "https"
  endpoint  = "https://ec2.eu-central-1.api.aws"
}

