output "input_bucket_name" {
  description = "Upload JPEGs to the jpeg/ prefix in this bucket"
  value       = module.s3.input_bucket_name
}

output "output_bucket_name" {
  description = "Converted images appear in jpeg/, png/, webp/, avif/ here"
  value       = module.s3.output_bucket_name
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

output "sqs_queue_url" {
  description = "Main SQS queue URL (for monitoring)"
  value       = module.sqs.queue_url
}

output "dlq_url" {
  description = "Dead letter queue URL — inspect this if images fail to process"
  value       = module.sqs.dlq_url
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "cloudwatch_dashboard_url" {
  description = "Direct link to the CloudWatch dashboard"
  value       = module.cloudwatch.dashboard_url
}

output "upload_command_example" {
  value = "aws s3 cp my-photo.jpg s3://${module.s3.input_bucket_name}/jpeg/my-photo.jpg"
}
