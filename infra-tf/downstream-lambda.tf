# Second Lambda for downstream services. This Lambda receive streams
# from Dynamo Db streams and publish the order info to SNS and then 
# the downstrem services

resource "aws_lambda_function" "downstream_lambda" {
  s3_bucket = "ttt-my-terraform-state"
  s3_key = var.py_files_var

  
  function_name    = "publish-data-function"
  role             = aws_iam_role.lambda_exec_role.arn #role is declared in the ord-service-lambda file
  handler          = "publish-data.lambda_handler"
  runtime = "python3.13"

  environment {
      variables = {
        SNS_TOPIC_ARN = aws_sns_topic.order_services_topic.arn
  }
}


  tags = {
    Environment = "production"
    Application = "downstream-lambda"
  }
}

# Resource for take the stream from Dynamo DB to downstream Lambda

resource "aws_lambda_event_source_mapping" "from_dyndb_to_downstreamLambda" {
  event_source_arn  = aws_dynamodb_table.products_dynamodb.stream_arn
  function_name     = aws_lambda_function.downstream_lambda.arn
  starting_position = "LATEST"

  tags = {
    Name = "dynamodb-stream-mapping"
  }
}

# IAM policy for let downstream_lambda take the stream data and publish them to SNS
# for simplicity, I use always the same lambda_exec_role
resource "aws_iam_role_policy_attachment" "attach_second_policy_to_role" {
  role = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.downstream_lambda_policy.arn
  
}

resource "aws_iam_policy" "downstream_lambda_policy" {
  name = "stream_sns_policy"
  description = "Custom policy for let Downstream Lambda read the stream data and publish to SNS"
  policy = data.aws_iam_policy_document.stream_and_sns_permissions.json
  
}

data "aws_iam_policy_document" "stream_and_sns_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetRecords",       # For reading from the stream
      "dynamodb:GetShardIterator", # For reading from the stream
      "dynamodb:DescribeStream",   # For reading from the stream
      "dynamodb:ListStreams",      # For reading from the stream
      "sns:Publish"                # For publishing to SNS
    ]
  }
}