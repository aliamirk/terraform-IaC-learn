resource "aws_dynamodb_table" "image_metadata" {
  name = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "image_id"

  attribute {
    name = "image_id"
    type = "S"
  }

  global_secondary_index {
    name = "filename-index"
    hash_key = "original_filename"
    projection_type = "ALL"
  }

  attribute {
    name = "original_filename"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = var.tags
}

