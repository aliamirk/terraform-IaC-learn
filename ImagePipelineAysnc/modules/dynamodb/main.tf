resource "aws_dynamodb_table" "image_metadata" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "image_id"

  attribute {
    name = "image_id"
    type = "S"
  }

  # GSI: query by original filename (for UI lookups)
  global_secondary_index {
    name            = "filename-index"
    hash_key        = "original_filename"
    projection_type = "ALL"
  }

  attribute {
    name = "original_filename"
    type = "S"
  }

  # GSI: query by original S3 key — used by idempotency check in Lambda
  global_secondary_index {
    name            = "source-key-index"
    hash_key        = "original_key"
    projection_type = "KEYS_ONLY"  # only need to know it exists, not the full item
  }

  attribute {
    name = "original_key"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = var.tags
}
