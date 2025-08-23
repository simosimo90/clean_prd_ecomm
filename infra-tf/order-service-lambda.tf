
# --- Data Sources to get current AWS Region and Account ID dynamically ---
# These are needed for constructing the ARN for the DynamoDB table.
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


# In this file is set up the Lambda funcction and the IAM role and policies for execute it and for operate on Dynamo DB

# Creating the Order Services Lambda. All the services backends will be inside this Lambda

resource "aws_lambda_function" "order_services_lambda" {
  s3_bucket = "ttt-my-terraform-state"
  s3_key = var.js_files_var

  function_name = "order-services-logic"
  role = aws_iam_role.lambda_exec_role.arn
  handler = "index.handler"
  runtime = "nodejs20.x"

  tags = {
  Environment = "production"
  Application = "ord-service-lambda"
}
}



# Defining an execution role for order-services-lambda (mandatory for all Lamdas)

resource "aws_iam_role" "lambda_exec_role" {
  name =  "lambda_exec_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  
}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
 
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_attachment" {
  role = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_custom_policy_for_dynamodb" {
  name = "lambda-DynDB-policy"
  description = "custom policy for: 1st Lambda perform CRUD on DynDB, 2nd receive the Stream"
  policy = data.aws_iam_policy_document.lambda1-policy.json
}


data "aws_iam_policy_document" "lambda1-policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:BatchWriteItem",
      #These one are the permissions from the Stream to the second lambda
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:DescribeStream",
      "dynamodb:ListStreams",
      #Permission for let Lambda receive messages from SQS
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [ 
      "arn:aws:dynamodb:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.products_dynamodb.name}",
      "arn:aws:dynamodb:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.products_dynamodb.name}/*", 
      # ARN of the stream, which is a different resource
      aws_dynamodb_table.products_dynamodb.stream_arn,
      aws_sns_topic.order_services_topic.arn,
      aws_sqs_queue.sqs_queue.arn
      ]
  }
}


resource "aws_iam_role_policy_attachment" "attach-lambda-dynamo-db-policy" {
  role = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_custom_policy_for_dynamodb.arn
}