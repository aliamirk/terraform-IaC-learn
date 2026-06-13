# ── Dead letter queue ───────────────────────────────────────────────────────
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-dlq"
  message_retention_seconds = 1209600 # 14 days — gives you time to inspect failures
  tags                      = var.tags
}

# ── Main queue ───────────────────────────────────────────────────────────────
resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-image-queue"
  visibility_timeout_seconds = 360  # must be > Lambda timeout (300s) + buffer
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20   # long polling — reduces empty receives & cost

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3  # after 3 failures → DLQ
  })

  tags = var.tags
}

# ── Allow S3 to publish to the queue ────────────────────────────────────────
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

# ── S3 → SQS notification (replaces the old S3 → Lambda direct trigger) ─────
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

# ── Lambda event source mapping — SQS triggers Lambda in batches ─────────────
resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn                   = aws_sqs_queue.main.arn
  function_name                      = var.lambda_function_arn
  batch_size                         = 10   # up to 10 messages per Lambda invoke
  maximum_batching_window_in_seconds = 30   # wait up to 30s to fill a batch
  enabled                            = true

  function_response_types = ["ReportBatchItemFailures"]
  # ^^^ critical: lets Lambda report partial failures so only failed
  # messages go back to the queue, not the whole batch
}
