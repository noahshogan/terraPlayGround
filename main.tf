# Configure the Random provider
# The Random provider is a simple provider that generates random values, useful in various infrastructure configurations
provider "random" {}

# Configure the AWS provider
# The AWS provider allows you to configure AWS resources
provider "aws" {
  region = "us-east-1"
}

# Create an IAM role for the Lambda function
# This IAM role provides permissions that determine what other AWS service resources the Lambda function can access
resource "aws_iam_role" "noah_role" {
  name               = "noah_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

# Generate a UUID for unique identification
# This value will be used to ensure the S3 bucket name is unique
resource "random_uuid" "bucket_id" {}

# Generate a unique 'pet' name
# This value will also be used to ensure the S3 bucket name is unique
resource "random_pet" "bucket_name" {
  length    = 2
  separator = "-"
}

# Create an S3 bucket with a unique name
# This bucket will store the files that will trigger the Lambda function
resource "aws_s3_bucket" "noah_bucket" {
  bucket = "noah-bucket-${random_pet.bucket_name.id}-${random_uuid.bucket_id.result}"

  tags = {
    Name        = "noah-bucket-${random_pet.bucket_name.id}-${random_uuid.bucket_id.result}"
    Environment = "Dev"
  }
}

# Create a DynamoDB table to store data from S3
# This table will store the data processed by the Lambda function
resource "aws_dynamodb_table" "s3_to_dynamodb" {
  name           = "s3_to_dynamodb"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"
  range_key      = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  tags = {
    Name        = "s3_to_dynamodb"
    Environment = "Dev"
  }
}

# Prepare the Lambda function's code by zipping it
# The Lambda function's code needs to be in a zip file in order to be uploaded to AWS
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./app"
  output_path = "noah_payload.zip"
}

# Create a Lambda function that processes data from S3 and stores it in DynamoDB
# This function is triggered when a new file is added to the S3 bucket
resource "aws_lambda_function" "s3_to_dynamodb" {
  function_name = "s3_to_dynamodb"
  handler       = "index.handler"
  runtime       = "nodejs14.x"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  role        = aws_iam_role.noah_role.arn
  timeout     = 60
  memory_size = 128
}

# Define a policy that allows the Lambda function to access S3, DynamoDB, and CloudWatch Logs
# This policy is necessary for the Lambda function to be able to read from S3, write to DynamoDB, and write logs to CloudWatch Logs
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.noah_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "dynamodb:PutItem",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach a policy that allows read access to S3 to the Lambda function's role
# This policy is necessary for the Lambda function to be able to read data from the S3 bucket
resource "aws_iam_role_policy_attachment" "s3_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.noah_role.name
}

# Attach a policy that allows full access to DynamoDB to the Lambda function's role
# This policy is necessary for the Lambda function to be able to write data to the DynamoDB table
resource "aws_iam_role_policy_attachment" "dynamodb_write" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.noah_role.name
}

# Create a notification configuration for the S3 bucket
# This configuration will cause the S3 bucket to send an event to the Lambda function whenever a new file is added
resource "aws_s3_bucket_notification" "bucket_notification" {
  depends_on = [aws_lambda_permission.allow_bucket]
  bucket     = aws_s3_bucket.noah_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_dynamodb.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# Define a permission that allows the S3 bucket to invoke the Lambda function
# This permission is necessary for the S3 bucket to be able to trigger the Lambda function
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_to_dynamodb.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.noah_bucket.arn
}

