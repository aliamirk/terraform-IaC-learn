
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-dlq"
  message_retention_seconds = 1209600 
  tags                      = var.tags
}

resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-image-queue"
  visibility_timeout_seconds = 360 
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20  

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3  
  })

  tags = var.tags
}

resource "aws_sqs_queue_policy" "allow_s3" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.main.arn
      Condition = {
        ArnLike = {
          "aws:SourceArn" = var.input_bucket_arn
        }
      }
    }]
  })
}

resource "aws_s3_bucket_notification" "to_sqs" {
  bucket = var.input_bucket_id

  queue {
    queue_arn     = aws_sqs_queue.main.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "jpeg/"
    filter_suffix = ".jpg"
  }

  queue {
    queue_arn     = aws_sqs_queue.main.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "jpeg/"
    filter_suffix = ".jpeg"
  }

  depends_on = [aws_sqs_queue_policy.allow_s3]
}


