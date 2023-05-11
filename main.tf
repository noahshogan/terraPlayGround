provider "random" {}

provider "aws" {
  region = "us-east-1"
}

# IAM Role
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

# Random UUID
resource "random_uuid" "bucket_id" {}

# Random Pet
resource "random_pet" "bucket_name" {
  length    = 2
  separator = "-"
}

# S3 Bucket
resource "aws_s3_bucket" "noah_bucket" {
  bucket = "noah-bucket-${random_pet.bucket_name.id}-${random_uuid.bucket_id.result}"

  tags = {
    Name        = "noah-bucket-${random_pet.bucket_name.id}-${random_uuid.bucket_id.result}"
    Environment = "Dev"
  }
}

# DynamoDB Table
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

# Lambda Archive File
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./app"
  output_path = "noah_payload.zip"
}

# Lambda Function
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

# IAM Role Policy
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

# IAM Role Policy Attachment for S3 Read Access
resource "aws_iam_role_policy_attachment" "s3_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.noah_role.name
}

# IAM Role Policy Attachment for DynamoDB Write Access
resource "aws_iam_role_policy_attachment" "dynamodb_write" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.noah_role.name
}

# S3 Bucket Notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  depends_on = [aws_lambda_permission.allow_bucket]
  bucket     = aws_s3_bucket.noah_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_dynamodb.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# Lambda Permission for S3 Bucket Access
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_to_dynamodb.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.noah_bucket.arn
}

