import os
import json
import logging
import boto3
import watchtower
from datetime import datetime, timezone
from pg8000.native import Connection
from botocore.exceptions import ClientError
import csv
import io
from dateutil.parser import parse as parse_date  # <-- new import

# --- Table schema: column definitions for each table ---
TABLE_COLUMNS = {
    "sales_order": [
        "sales_order_id", "created_at", "last_updated", "design_id", "staff_id", "counterparty_id",
        "units_sold", "unit_price", "currency_id", "agreed_delivery_date", "agreed_payment_date", "agreed_delivery_location_id"
    ],
    "design": [
        "design_id", "created_at", "last_updated", "design_name", "file_location", "file_name"
    ],
    "currency": [
        "currency_id", "currency_code", "created_at", "last_updated"
    ],
    "staff": [
        "staff_id", "first_name", "last_name", "department_id", "email_address", "created_at", "last_updated"
    ],
    "counterparty": [
        "counterparty_id", "counterparty_legal_name", "legal_address_id", "commercial_contact",
        "delivery_contact", "created_at", "last_updated"
    ],
    "address": [
        "address_id", "address_line_1", "address_line_2", "district", "city", "postal_code",
        "country", "phone", "created_at", "last_updated"
    ],
    "department": [
        "department_id", "department_name", "location", "manager", "created_at", "last_updated"
    ],
    "purchase_order": [
        "purchase_order_id", "created_at", "last_updated", "staff_id", "counterparty_id", "item_code",
        "item_quantity", "item_unit_price", "currency_id", "agreed_delivery_date", "agreed_payment_date", "agreed_delivery_location_id"
    ],
    "payment_type": [
        "payment_type_id", "payment_type_name", "created_at", "last_updated"
    ],
    "payment": [
        "payment_id", "created_at", "last_updated", "transaction_id", "counterparty_id", "payment_amount",
        "currency_id", "payment_type_id", "paid", "payment_date", "company_ac_number", "counterparty_ac_number"
    ],
    "transaction": [
        "transaction_id", "transaction_type", "sales_order_id", "purchase_order_id", "created_at", "last_updated"
    ]
}

TABLES = list(TABLE_COLUMNS.keys())

# --- Config ---
LOG_GROUP = os.getenv("LOG_GROUP", "/aws/lambda/ingestion-lambda")
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")
S3_BUCKET = os.getenv("S3_BUCKET", "etl-data-project-007")
STATE_KEY = "state/last_updated.json"

# --- Logging Setup ---
logger = logging.getLogger("ingestion-logger")
if not logger.handlers:
    logger.setLevel(logging.INFO)
    logger.addHandler(logging.StreamHandler())
    try:
        logger.addHandler(watchtower.CloudWatchLogHandler(log_group=LOG_GROUP))
    except Exception:
        pass  # Local dev: no CloudWatch

s3 = boto3.client("s3")
sns_client = boto3.client("sns", region_name="eu-west-2")

def send_sns_notification(subject: str, message: str):
    try:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        logger.info(f"SNS notification sent: {subject}")
    except ClientError as e:
        logger.error(f"Failed to send SNS notification: {e}")

def get_secrets(secretname="TotesysDatabase"):
    sm_client = boto3.client("secretsmanager")
    response = sm_client.get_secret_value(SecretId=secretname)
    return json.loads(response['SecretString'])

def load_state():
    try:
        response = s3.get_object(Bucket=S3_BUCKET, Key=STATE_KEY)
        return json.loads(response["Body"].read().decode("utf-8"))
    except s3.exceptions.NoSuchKey:
        logger.info("No previous state found. Full ingest will be performed.")
        return {}
    except Exception as e:
        logger.error(f"Error loading state: {e}")
        return {}

def save_state(state):
    try:
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=STATE_KEY,
            Body=json.dumps(state).encode("utf-8")
        )
        logger.info("State saved to S3")
    except Exception as e:
        logger.error(f"Error saving state: {e}")
        raise

def extract_table(conn: Connection, table: str, since: str = None):
    """
    Extract table data. Only uses incremental (WHERE last_updated > ...) if
    'last_updated' is a column in the table AND 'since' is provided.
    Always ensure since is a string with correct timestamp format.
    """
    if table not in TABLES:
        raise ValueError(f"Table '{table}' is not allowed.")
    columns = TABLE_COLUMNS[table]
    try:
        base_query = f'SELECT {", ".join(columns)} FROM "{table}"'
        if "last_updated" in columns and since is not None and since != "":
            # Defensive: force the format to match timestamp
            try:
                since_dt = parse_date(str(since))
                since_str = since_dt.strftime("%Y-%m-%d %H:%M:%S.%f")
            except Exception:
                since_str = str(since)
            logger.info(f"Extracting {table} since={since_str!r} (type={type(since_str)})")
            query = f'{base_query} WHERE last_updated > @1'
            rows = conn.run(query, (since_str,))
        else:
            logger.info(f"Extracting {table} (full load, no since or no last_updated field)")
            rows = conn.run(base_query)
        records = [dict(zip(columns, row)) for row in rows]
        return records, columns
    except Exception as e:
        logger.error(f"Error fetching table '{table}': {repr(e)}")
        raise

def transform_rows(rows):
    return rows

def load_to_s3(table: str, records, columns):
    if not records:
        logger.info(f"No new rows for table {table}. Skipping upload.")
        return None, None
    now = datetime.now(timezone.utc)
    timestamp = now.strftime("%Y-%m-%dT%H-%M-%S")
    year, month, day = now.strftime("%Y %m %d").split()
    path_prefix = f"ingestion/{table}/{year}/{month}/{day}/{timestamp}"

    # Prepare CSV in memory
    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=columns)
    writer.writeheader()
    writer.writerows(records)
    data_bytes = buffer.getvalue().encode("utf-8")
    file_key = f"{path_prefix}/data.csv"
    s3.put_object(
        Body=data_bytes,
        Bucket=S3_BUCKET,
        Key=file_key
    )
    # Save metadata as JSON
    metadata = {
        "table": table,
        "timestamp": timestamp,
        "row_count": len(records),
        "columns": columns,
        "schema_version": "1.0",
        "last_updated_field": "last_updated",
        "format": "csv"
    }
    metadata_key = f"{path_prefix}/metadata.json"
    s3.put_object(
        Body=json.dumps(metadata).encode("utf-8"),
        Bucket=S3_BUCKET,
        Key=metadata_key
    )
    logger.info(f"Uploaded {len(records)} rows from {table} to {file_key}")
    return file_key, records

def real_main():
    """Ingest all tables and return a dict of S3 keys for new data."""
    try:
        logger.info("Starting ingestion pipeline")
        creds = get_secrets()
        conn = Connection(
            user=creds["DB_USER"],
            password=creds["DB_PASSWORD"],
            host=creds["DB_HOST"],
            port=int(creds["DB_PORT"]),
            database=creds["DB_NAME"]
        )
        previous_state = load_state()
        new_state = {}
        all_s3_keys = {}
        total_rows = 0

        for table in TABLES:
            try:
                since = previous_state.get(table)
                if isinstance(since, datetime):
                    since = since.strftime("%Y-%m-%d %H:%M:%S.%f")
                elif since is not None:
                    since = str(since)
                rows, columns = extract_table(conn, table, since)
                cleaned = transform_rows(rows)
                file_key, result_rows = load_to_s3(table, cleaned, columns)
                if result_rows:
                    max_ts = max([r["last_updated"] for r in result_rows if "last_updated" in r])
                    new_state[table] = str(max_ts)
                    total_rows += len(result_rows)
                    all_s3_keys.setdefault(table, []).append(file_key)
            except Exception as e:
                logger.error(f"Failed to ingest table '{table}': {e}")
                continue

        conn.close()
        save_state(new_state)
        summary = f"Ingested {total_rows} rows from {len(TABLES)} tables."
        logger.info(summary)
        send_sns_notification("Ingestion Success", summary)

        return {
            "status": "success",
            "rows": total_rows,
            "s3_keys": all_s3_keys
        }
    except Exception as e:
        logger.error(f"Ingestion failed: {e}")
        send_sns_notification("Ingestion Failed", str(e))
        raise

def main(event, context):
    logger.info("Lambda triggered")
    return real_main()

if __name__ == "__main__":
    try:
        from pprint import pprint
        pprint(real_main())
    except Exception as e:
        print(f"Error during ingestion: {e}")
