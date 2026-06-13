import boto3
import os
import uuid
import json
import logging
from datetime import datetime, timezone
from io import BytesIO
from PIL import Image

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]
DYNAMODB_TABLE = os.environ["DYNAMODB_TABLE"]
FORMATS = ["jpeg", "png", "webp", "avif"]


def lambda_handler(event, context):
    table = dynamodb.Table(DYNAMODB_TABLE)

    for record in event["Records"]:
        bucket_name = record["s3"]["bucket"]["name"]
        object_key = record["s3"]["object"]["key"]

        # Only process files in the /jpeg prefix
        if not object_key.startswith("jpeg/"):
            logger.info(f"Skipping non-jpeg prefix key: {object_key}")
            continue

        filename = os.path.basename(object_key)
        name_without_ext = os.path.splitext(filename)[0]
        image_id = str(uuid.uuid4())

        logger.info(f"Processing: {object_key} from bucket: {bucket_name}")

        # Download original image
        response = s3.get_object(Bucket=bucket_name, Key=object_key)
        image_data = response["Body"].read()
        original_size = len(image_data)

        image = Image.open(BytesIO(image_data))
        # Convert to RGB so all formats are compatible (AVIF/WebP don't support CMYK etc.)
        if image.mode not in ("RGB", "RGBA"):
            image = image.convert("RGB")

        formats_created = []
        s3_keys = {}

        for fmt in FORMATS:
            output_key = f"{fmt}/{name_without_ext}.{fmt}"
            buffer = BytesIO()

            if fmt == "jpeg":
                # Re-save the original as JPEG into the /jpeg output folder
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
                # Pillow supports AVIF via pillow-avif-plugin; fall back gracefully
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
            logger.info(f"Uploaded {fmt} → s3://{OUTPUT_BUCKET}/{output_key}")

        # Write metadata to DynamoDB
        item = {
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
        }

        table.put_item(Item=item)
        logger.info(f"Metadata written to DynamoDB: image_id={image_id}")

    return {"statusCode": 200, "body": json.dumps("Processing complete")}
