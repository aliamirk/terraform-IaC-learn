import boto3
import os
import uuid
import json
import logging
from datetime import datetime, timezone
from io import BytesIO
from PIL import Image
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
cloudwatch = boto3.client("cloudwatch")

OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]
DYNAMODB_TABLE = os.environ["DYNAMODB_TABLE"]
NAMESPACE = os.environ.get("METRICS_NAMESPACE", "ImagePipeline")
FORMATS = ["jpeg", "png", "webp", "avif"]


def put_metric(name, value, unit="Count", dimensions=None):
    """Emit a single custom CloudWatch metric."""
    try:
        dims = dimensions or [{"Name": "Environment", "Value": os.environ.get("ENVIRONMENT", "dev")}]
        cloudwatch.put_metric_data(
            Namespace=NAMESPACE,
            MetricData=[{
                "MetricName": name,
                "Value": value,
                "Unit": unit,
                "Dimensions": dims,
            }]
        )
    except Exception as e:
        logger.warning(f"Failed to emit metric {name}: {e}")


def is_duplicate(table, image_key):
    """
    Idempotency check — query DynamoDB GSI by original_key.
    Returns True if we have already successfully processed this exact S3 key.
    """
    try:
        resp = table.query(
            IndexName="source-key-index",
            KeyConditionExpression="original_key = :k",
            ExpressionAttributeValues={":k": image_key},
            Limit=1,
        )
        return len(resp.get("Items", [])) > 0
    except ClientError as e:
        logger.warning(f"Idempotency check failed for {image_key}: {e}")
        return False  # fail open — process it rather than silently skip


def process_single_image(table, bucket_name, object_key):
    """
    Download, convert, upload all formats, write metadata.
    Returns the image_id on success.
    Raises on failure so the caller can report the SQS message as failed.
    """
    filename = os.path.basename(object_key)
    name_without_ext = os.path.splitext(filename)[0]
    image_id = str(uuid.uuid4())

    logger.info(f"Processing: s3://{bucket_name}/{object_key}")

    response = s3.get_object(Bucket=bucket_name, Key=object_key)
    image_data = response["Body"].read()
    original_size = len(image_data)

    image = Image.open(BytesIO(image_data))
    if image.mode not in ("RGB", "RGBA"):
        image = image.convert("RGB")

    formats_created = []
    s3_keys = {}

    for fmt in FORMATS:
        output_key = f"{fmt}/{name_without_ext}.{fmt}"
        buffer = BytesIO()

        if fmt == "jpeg":
            save_image = image.convert("RGB")
            save_image.save(buffer, format="JPEG", quality=90)
            content_type = "image/jpeg"
        elif fmt == "png":
            image.save(buffer, format="PNG", optimize=True)
            content_type = "image/png"
        elif fmt == "webp":
            image.save(buffer, format="WEBP", quality=85, method=6)
            content_type = "image/webp"
        elif fmt == "avif":
            try:
                image.save(buffer, format="AVIF", quality=80)
                content_type = "image/avif"
            except Exception as e:
                logger.warning(f"AVIF conversion failed, skipping: {e}")
                continue

        buffer.seek(0)
        s3.put_object(
            Bucket=OUTPUT_BUCKET,
            Key=output_key,
            Body=buffer,
            ContentType=content_type,
        )
        formats_created.append(fmt)
        s3_keys[fmt] = output_key

    # Write metadata + idempotency record atomically
    table.put_item(Item={
        "image_id": image_id,
        "original_filename": filename,
        "original_key": object_key,
        "source_bucket": bucket_name,
        "output_bucket": OUTPUT_BUCKET,
        "original_size_bytes": original_size,
        "image_width": image.width,
        "image_height": image.height,
        "formats_created": formats_created,
        "s3_keys": s3_keys,
        "processed_at": datetime.now(timezone.utc).isoformat(),
        "status": "success",
    })

    logger.info(f"Done: image_id={image_id}, formats={formats_created}")
    return image_id


def lambda_handler(event, context):
    table = dynamodb.Table(DYNAMODB_TABLE)

    records = event.get("Records", [])
    total = len(records)
    processed = 0
    skipped_dupes = 0
    failed_message_ids = []

    logger.info(f"Batch received: {total} messages")
    put_metric("BatchSize", total)

    for record in records:
        message_id = record["messageId"]
        try:
            body = json.loads(record["body"])

            # SQS wraps the S3 event; handle both direct S3 test events and real ones
            s3_records = body.get("Records", [])
            if not s3_records:
                logger.warning(f"No S3 records in message {message_id}, skipping")
                continue

            for s3_record in s3_records:
                bucket_name = s3_record["s3"]["bucket"]["name"]
                object_key = s3_record["s3"]["object"]["key"]

                if not object_key.startswith("jpeg/"):
                    logger.info(f"Skipping non-jpeg prefix: {object_key}")
                    continue

                # ── Idempotency check ──────────────────────────────────────
                if is_duplicate(table, object_key):
                    logger.info(f"Duplicate detected, skipping: {object_key}")
                    skipped_dupes += 1
                    put_metric("DuplicateSkipped", 1)
                    continue

                process_single_image(table, bucket_name, object_key)
                processed += 1
                put_metric("ImageProcessed", 1)

        except Exception as e:
            logger.error(f"Failed to process message {message_id}: {e}", exc_info=True)
            failed_message_ids.append(message_id)
            put_metric("ProcessingError", 1)

    logger.info(
        f"Batch complete — processed: {processed}, "
        f"duplicates skipped: {skipped_dupes}, "
        f"failures: {len(failed_message_ids)}"
    )
    put_metric("DuplicateSkipRate", skipped_dupes / max(total, 1) * 100, unit="Percent")

    # Report partial failures — only failed messages return to queue
    # Successfully processed messages are automatically deleted
    return {
        "batchItemFailures": [
            {"itemIdentifier": mid} for mid in failed_message_ids
        ]
    }
