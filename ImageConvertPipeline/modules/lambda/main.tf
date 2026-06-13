
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/lambda_src"
  output_path = "${path.module}/lambda_function.zip"
  excludes    = ["requirements.txt"]
}

# The zip already exists at this path; Terraform just uploads it.
# If the file is missing, run:  ./build_layer.sh
resource "aws_lambda_layer_version" "pillow" {
  filename            = "${path.module}/lambda_layer.zip"
  layer_name          = "${var.project_name}-pillow-layer"
  compatible_runtimes = ["python3.12"]
  source_code_hash    = filebase64sha256("${path.module}/lambda_layer.zip")
}

resource "aws_lambda_function" "image_converter" {
  function_name    = "${var.project_name}-image-converter"
  role             = var.lambda_role_arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 300
  memory_size      = 1024
  layers           = [aws_lambda_layer_version.pillow.arn]

  environment {
    variables = {
      OUTPUT_BUCKET  = var.output_bucket_name
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  tags = var.tags
}

# ── CloudWatch log group with 30-day retention ──────────────────────────────
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.image_converter.function_name}"
  retention_in_days = 30
  tags              = var.tags
}
