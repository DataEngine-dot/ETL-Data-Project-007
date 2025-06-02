import os
import json
import logging
import csv
import gzip
import io
from datetime import datetime, timezone
from io import StringIO
import boto3
import watchtower
from botocore.exceptions import ClientError
from pprint import pprint
from pg8000 import connect

# --- Logging setup ---
LOG_GROUP = os.getenv("LOG_GROUP", "/aws/lambda/ingestion-lambda")
logger = logging.getLogger("ingestion-logger")
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())
logger.addHandler(watchtower.CloudWatchLogHandler(log_group=LOG_GROUP, create_log_group=True))

# --- SNS client for sending success/failure alerts ---
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN", "arn:aws:sns:eu-west-2:645583760702:ingestion-alerts")
sns_client = boto3.client("sns", region_name="eu-west-2")

# --- S3 client for storing ingested data ---
S3_BUCKET = os.getenv("S3_BUCKET", "ingestion")
s3 = boto3.client("s3")

# --- SNS notification utilities ---
def notify_success(message: str):
    send_sns_notification("Ingestion Success", message)
    
def notify_failure(message: str):
    send_sns_notification("Ingestion Failed", message)
    
def send_sns_notification(subject: str, message: str):
    try:
        boto3.client("sns").publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        logger.info(f"SNS notification sent: {subject}")
    except ClientError as e:
        logger.error(f"Failed to send SNS notification: {e}")

# --- Data serialization utilities ---
def rows_to_csv(rows, columns):
    """
    Convert a list of row tuples and column names into a CSV string.
    Handles escaping of commas, quotes, and newlines.
    """
    output = StringIO()
    output.write(",".join(columns) + "\n")
    for row in rows:
        escaped = []
        for val in row:
            if val is None:
                escaped.append("")
            else:
                s = str(val)
                if "," in s or '"' in s or "\n" in s:
                    s = '"' + s.replace('"', '""') + '"'
                escaped.append(s)
        output.write(",".join(escaped) + "\n")
    return output.getvalue()

def save_to_s3(table_name, rows, columns):
    """
    Compress and upload table data to S3 in a structured time-based key format.
    Stores as .csv.gz with column headers.
    """
    now = datetime.now(tz=timezone.utc)
    timestamp = now.strftime("%Y-%m-%dT%H-%M-%S.%fZ")
    year = now.strftime("%Y")
    month = now.strftime("%m")
    day = now.strftime("%d")
    
    key = f"{year}/{month}/{day}/{table_name}_{timestamp}.csv.gz"

    buffer = io.BytesIO()
    with gzip.GzipFile(mode='w', fileobj=buffer) as gz:
        with io.TextIOWrapper(gz, encoding='utf-8') as wrapper:
            writer = csv.writer(wrapper)
            writer.writerow(columns)
            writer.writerows(rows)

    buffer.seek(0)
    s3.upload_fileobj(buffer, S3_BUCKET, key)
    logger.info(f"Saved {table_name} with {len(rows)} rows to s3://{S3_BUCKET}/{key}")

def get_timestamp():
    """Return current UTC timestamp in ISO 8601 format."""
    return datetime.now(tz=timezone.utc).strftime("%Y-%m-%dT%H-%M-%SZ")

def get_secrets(secretname="TotesysDatabase"):
    """
    Retrieve database credentials from AWS Secrets Manager.
    Fallback mechanism if environment variables are not provided.
    """
    try:
        session = boto3.Session()
        sm_client = session.client("secretsmanager")
        response = sm_client.get_secret_value(SecretId=secretname)
    except ClientError as e:
        raise RuntimeError(f"Failed to retrieve secrets: {e}")
    return json.loads(response['SecretString'])

# --- Core ingestion logic ---

def real_main():
    """
    Entry point for ETL ingestion logic.
    This can be reused from tests, scripts, and within Lambda.
    """
    try:
        logger.info("Starting ingestion process...")

        # Load credentials from env vars, fallback to Secrets Manager
        db_user = os.getenv("DB_USER")
        db_password = os.getenv("DB_PASSWORD")
        db_host = os.getenv("DB_HOST")
        db_port = int(os.getenv("DB_PORT", 5432))
        db_name = os.getenv("DB_NAME")

        if not all([db_user, db_password, db_host, db_name]):
            logger.info("DB credentials missing in environment, trying Secrets Manager...")
            creds = get_secrets()
            db_user = creds.get("DB_USER")
            db_password = creds.get("DB_PASSWORD")
            db_host = creds.get("DB_HOST")
            db_port = int(creds.get("DB_PORT", 5432))
            db_name = creds.get("DB_NAME")

        # Connect to PostgreSQL database
        conn = connect(
            user=db_user,
            password=db_password,
            host=db_host,
            port=db_port,
            database=db_name
        )
        cursor = conn.cursor()

        # Retrieve list of all public tables
        cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='public';")
        tables = [row[0] for row in cursor.fetchall()]

        total_rows = 0
        for table in tables:
            logger.info(f"Ingesting table: {table}")
            cursor.execute(f"SELECT * FROM {table};")
            rows = cursor.fetchall()

            if rows:
                columns = [desc[0] for desc in cursor.description]
                save_to_s3(table, rows, columns)
                logger.info(f"Table {table}: {len(rows)} rows exported.")
                total_rows += len(rows)
            else:
                logger.info(f"Table {table} is empty.")

        cursor.close()
        conn.close()

        summary = f"Ingestion completed successfully.\nTables processed: {len(tables)}\nTotal rows: {total_rows}"
        logger.info(summary)
        notify_success(summary)
        return {"status": "success", "tables": tables, "total_rows": total_rows}

    except Exception as e:
        error_msg = f"ETL ingestion failed: {str(e)}"
        logger.error(error_msg)
        notify_failure(error_msg)
        raise

# --- Lambda handler (entry point for AWS Lambda) ---
def main(event, context):
    logger.info("Lambda handler started")
    return real_main()


# --- for local testing ---
if __name__ == "__main__":
    try:
        result = real_main()
        pprint(result)
    except Exception as e:
        print(f"Error during ingestion: {e}")
