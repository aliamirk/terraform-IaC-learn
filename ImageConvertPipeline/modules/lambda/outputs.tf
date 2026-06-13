output "function_arn" {
  value = aws_lambda_function.image_converter.arn
}

output "function_name" {
  value = aws_lambda_function.image_converter.function_name
}
