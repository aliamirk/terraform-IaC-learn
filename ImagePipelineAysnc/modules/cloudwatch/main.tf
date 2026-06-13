
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-pipeline-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}


resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors"
  alarm_description   = "Lambda error rate is elevated"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = var.lambda_function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "dlq_depth" {
  alarm_name          = "${var.project_name}-dlq-not-empty"
  alarm_description   = "Messages are landing in the DLQ — check Lambda logs"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = var.dlq_name }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  alarm_name          = "${var.project_name}-queue-depth-high"
  alarm_description   = "SQS queue depth is growing — Lambda may be falling behind"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = var.sqs_queue_name }
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 3
  threshold           = 100
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration_p99" {
  alarm_name          = "${var.project_name}-lambda-duration-high"
  alarm_description   = "Lambda p99 duration is approaching the 5 minute timeout"
  namespace           = "AWS/Lambda"
  metric_name         = "Duration"
  dimensions          = { FunctionName = var.lambda_function_name }
  extended_statistic  = "p99"
  period              = 300
  evaluation_periods  = 2
  threshold           = 240000 # 240 seconds in ms — 80% of 300s timeout
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = var.tags
}

resource "aws_cloudwatch_dashboard" "pipeline" {
  dashboard_name = "${var.project_name}-pipeline"

  dashboard_body = jsonencode({
    widgets = [

      # Row 1: Lambda health
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "Lambda — invocations & errors"
          view   = "timeSeries"
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name],
            ["AWS/Lambda", "Errors",      "FunctionName", var.lambda_function_name, { color = "#d13212" }],
            ["AWS/Lambda", "Throttles",   "FunctionName", var.lambda_function_name, { color = "#ff9900" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "Lambda — duration (p50 / p90 / p99)"
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", var.lambda_function_name, { stat = "p50" }],
            ["AWS/Lambda", "Duration", "FunctionName", var.lambda_function_name, { stat = "p90", color = "#ff9900" }],
            ["AWS/Lambda", "Duration", "FunctionName", var.lambda_function_name, { stat = "p99", color = "#d13212" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "Lambda — concurrent executions"
          view   = "timeSeries"
          period = 60
          stat   = "Maximum"
          metrics = [
            ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", var.lambda_function_name]
          ]
        }
      },

      # Row 2: SQS queues
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "SQS — queue depth"
          view   = "timeSeries"
          period = 60
          stat   = "Maximum"
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible",   "QueueName", var.sqs_queue_name, { label = "Waiting" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesNotVisible", "QueueName", var.sqs_queue_name, { label = "In flight" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "DLQ — messages (should always be 0)"
          view   = "timeSeries"
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.dlq_name, { color = "#d13212", label = "DLQ depth" }]
          ]
          annotations = {
            horizontal = [{ value = 1, label = "Any DLQ message = alarm", color = "#d13212" }]
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "SQS — message age (oldest message)"
          view   = "timeSeries"
          period = 60
          stat   = "Maximum"
          metrics = [
            ["AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", var.sqs_queue_name]
          ]
        }
      },

      # Row 3: Custom pipeline metrics
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 8
        height = 6
        properties = {
          title  = "Pipeline — images processed vs errors"
          view   = "timeSeries"
          period = 300
          stat   = "Sum"
          metrics = [
            [var.metrics_namespace, "ImageProcessed",  "Environment", var.environment, { label = "Processed", color = "#1d8102" }],
            [var.metrics_namespace, "ProcessingError",  "Environment", var.environment, { label = "Errors",    color = "#d13212" }],
            [var.metrics_namespace, "DuplicateSkipped", "Environment", var.environment, { label = "Dupes skipped", color = "#ff9900" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 12
        width  = 8
        height = 6
        properties = {
          title  = "Pipeline — duplicate skip rate (%)"
          view   = "timeSeries"
          period = 300
          stat   = "Average"
          metrics = [
            [var.metrics_namespace, "DuplicateSkipRate", "Environment", var.environment]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 12
        width  = 8
        height = 6
        properties = {
          title  = "Pipeline — batch size"
          view   = "timeSeries"
          period = 300
          stat   = "Average"
          metrics = [
            [var.metrics_namespace, "BatchSize", "Environment", var.environment]
          ]
        }
      },

      # Row 4: DynamoDB
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "DynamoDB — read/write consumed capacity"
          view   = "timeSeries"
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits",  "TableName", var.dynamodb_table_name],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", var.dynamodb_table_name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "DynamoDB — latency (successful requests)"
          view   = "timeSeries"
          period = 60
          stat   = "p99"
          metrics = [
            ["AWS/DynamoDB", "SuccessfulRequestLatency", "TableName", var.dynamodb_table_name, "Operation", "PutItem"],
            ["AWS/DynamoDB", "SuccessfulRequestLatency", "TableName", var.dynamodb_table_name, "Operation", "Query"]
          ]
        }
      },

      # Row 5: Alarm status overview
      {
        type   = "alarm"
        x      = 0
        y      = 24
        width  = 24
        height = 3
        properties = {
          title = "Alarm status overview"
          alarms = [
            aws_cloudwatch_metric_alarm.lambda_errors.arn,
            aws_cloudwatch_metric_alarm.dlq_depth.arn,
            aws_cloudwatch_metric_alarm.queue_depth.arn,
            aws_cloudwatch_metric_alarm.lambda_duration_p99.arn
          ]
        }
      }
    ]
  })
}
