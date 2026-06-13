resource "aws_s3_bucket" "input" {
    bucket = var.input_bucket_name
    force_destroy = true
    tags = var.tags
}

resource "aws_s3_bucket" "output" {
    bucket = var.output_bucket_name
    force_destroy = true
    tags = var.tags
}


resource "aws_s3_bucket_public_access_block" "for_input" {
  bucket = aws_s3_bucket.input.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_public_access_block" "for_output" {
  bucket = aws_s3_bucket.output.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "ver_for_input" {
  bucket = aws_s3_bucket.input.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "lfc_for_input" {
  bucket = aws_s3_bucket.input.id

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
    filter {}
  }

  rule {
    id = "remove-expired-objects"

    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    filter {}
  }
}

resource "aws_lambda_permission" "allow_s3" {
    statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input.arn  
}

resource "aws_s3_bucket_notification" "input_trigger" {
  bucket = aws_s3_bucket.input.id
  
  lambda_function {
    lambda_function_arn = var.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "jpeg/"
    filter_suffix       = ".jpg"
  }

  lambda_function {
    lambda_function_arn = var.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "jpeg/"
    filter_suffix       = ".jpeg"
  }
 
  depends_on = [aws_lambda_permission.allow_s3]
}

