output "input_bucket_name" {
  description = "Upload JPEGs to the jpeg/ prefix in this bucket"
  value       = module.s3.input_bucket_name
}

output "output_bucket_name" {
  description = "Converted images appear in png/, webp/, avif/, jpeg/ here"
  value       = module.s3.output_bucket_name
}

output "lambda_function_name" {
  description = "Name of the image converter Lambda"
  value       = module.lambda.function_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table storing image metadata"
  value       = module.dynamodb.table_name
}

output "upload_command_example" {
  description = "Example AWS CLI command to upload a test image"
  value       = "aws s3 cp my-photo.jpg s3://${module.s3.input_bucket_name}/jpeg/my-photo.jpg"
}
