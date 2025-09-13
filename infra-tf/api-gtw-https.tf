# Here we create the API Gateway for connect to the order services runned in a Lamda Function

resource "aws_apigatewayv2_api" "api_ord_services" {
  name = "order-service-http-api"
  protocol_type = "HTTP"
  ip_address_type = "dualstack"
}

resource "aws_apigatewayv2_integration" "integration_api" {
  api_id              = aws_apigatewayv2_api.api_ord_services.id
  credentials_arn     = aws_iam_role.api_int_role.arn
  description         = "Api gateway integration with SQS"
  integration_type    = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"
  integration_method  = "POST"

  request_parameters = {
    "QueueUrl" = "${aws_sqs_queue.sqs_queue.url}",
    "MessageBody" = "$request.body", 
  }
}

resource "aws_apigatewayv2_route" "routing" {
  api_id    = aws_apigatewayv2_api.api_ord_services.id
  route_key = "POST /orders"
  target = "integration/${aws_apigatewayv2_integration.integration_api.id}"

}

resource "aws_apigatewayv2_stage" "staging_api" {
  api_id = aws_apigatewayv2_api.api_ord_services.id
  name = "my-stage"
  auto_deploy = true
}

# IAM role for API Gateway for send messages to SQS
resource "aws_iam_role" "api_int_role" {
  name = "apigtw_role"
  #This assume_role_policy define WHO (API Gateway) can assume this role
  assume_role_policy = data.aws_iam_policy_document.apigtw_access_role_policy.json
  
}

# Data source for the assume_role policy argument inside aws_iam_role (Trusted identity)
data "aws_iam_policy_document" "apigtw_access_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


# IAM policy for API Gateway send messages to the SQS queue
resource "aws_iam_policy" "api_to_sqs" {
  name = "api_to_sqs_policy"
  description = "policy for let API Gateway send messages to SQS queue"
  policy = data.aws_iam_policy_document.api_to_sqs_policy_source.json
}

data "aws_iam_policy_document" "api_to_sqs_policy_source" {
  statement {
    effect = "Allow"
    actions = ["sqs:SendMessage"]
    resources = ["${aws_sqs_queue.sqs_queue.arn}"]

  }

}