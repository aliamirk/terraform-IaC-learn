output "lambda_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
}

output "lambda_role_name" {
  value = aws_iam_role.lambda_exec_role.name
}