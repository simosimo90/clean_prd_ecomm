# Python code for take data from Dynamo db stream and publish on SNS

import json
import os
import boto3

# Initialize the SNS client
sns_client = boto3.client('sns')

# Get the SNS Topic ARN from environment variables
# This variable will be set in your Terraform code.
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    """
    AWS Lambda handler function that processes DynamoDB Stream events
    and publishes relevant data to an SNS Topic.
    """
    print("Received event from DynamoDB Stream:", json.dumps(event, indent=2))

    if not SNS_TOPIC_ARN:
        print("ERROR: SNS_TOPIC_ARN environment variable is not set. Cannot publish to SNS.")
        # In a real-world scenario, you might send this to a Dead Letter Queue (DLQ)
        # or raise an exception to trigger a retry.
        raise ValueError("SNS_TOPIC_ARN environment variable is missing.")

    for record in event['Records']:
        # DynamoDB Stream records contain 'eventName' (INSERT, MODIFY, REMOVE)
        # and 'dynamodb' (containing 'NewImage', 'OldImage', 'Keys', etc.)

        print(f"Processing record ID: {record['eventID']}, Event Name: {record['eventName']}")

        # We are interested in new or modified data for downstream services
        if record['eventName'] == 'INSERT' or record['eventName'] == 'MODIFY':
            try:
                # Extract the 'NewImage' (the item after the change)
                # DynamoDB JSON format is verbose (e.g., {"S": "value"}, {"N": "123"})
                # For a PoC, we'll just stringify the raw NewImage.
                # In a real app, you'd deserialize this into a more usable Python dict.
                new_image = record['dynamodb']['NewImage']
                message_body = json.dumps(new_image) # Convert the extracted data to a JSON string

                # Publish the message to the SNS Topic
                sns_response = sns_client.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Message=message_body,
                    Subject=f"DynamoDB Item {record['eventName']} Notification" # Subject for the email/notification
                )
                print(f"Successfully published message to SNS. MessageId: {sns_response['MessageId']}")

            except Exception as e:
                print(f"ERROR: Failed to process record or publish to SNS: {e}")
                # Depending on your error handling strategy, you might:
                # 1. Log the error and continue (as done here).
                # 2. Re-raise the exception to trigger Lambda retries (if configured).
                # 3. Send the failed record to a Dead Letter Queue (DLQ) for later inspection.
                continue # Continue to the next record if one fails

        elif record['eventName'] == 'REMOVE':
            # Handle deletions if your downstream services need to react to them
            print(f"Item removed: {record['dynamodb']['Keys']}")
            # You might publish a different message for REMOVE events
            # sns_client.publish(TopicArn=SNS_TOPIC_ARN, Message=json.dumps(record['dynamodb']['Keys']), Subject='DynamoDB Item Removed')

    return {
        'statusCode': 200,
        'body': json.dumps('Successfully processed DynamoDB Stream records.')
    }