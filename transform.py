import pandas as pd
import boto3
import gzip
import io
import pyarrow as pa
import pyarrow.parquet as pq
import logging
import json
from datetime import datetime, timezone


logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")

SOURCE_BUCKET = "ingestion-bucket-zone-etl-project"
TARGET_BUCKET = "processed-bucket-zone-etl-project"

TIMESTAMP_FILE = "transformation/last_processed.json"

now = datetime.now(tz=timezone.utc)
timestamp = now.strftime("%Y-%m-%dT%H-%M-%S.%fZ")
year = now.strftime("%Y")
month = now.strftime("%m")
day = now.strftime("%d")

def list_matching_files(bucket, prefix, table_names):
    matching_files = []
    paginator = s3.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket, Prefix=prefix)

    for page in pages:
        for obj in page.get("Contents", []):
            key = obj["Key"]
            if key.endswith(".csv.gz") and any(name in key for name in table_names):
                matching_files.append(key)

    return matching_files

def read_csv_from_s3(bucket, key):
    logger.info(f"Reading file from s3://{bucket}/{key}")
    response = s3.get_object(Bucket=bucket, Key=key)
    with gzip.GzipFile(fileobj=response['Body']) as gz:
        return pd.read_csv(gz)

def write_parquet_to_s3(df, bucket, key):
    table = pa.Table.from_pandas(df)
    buffer = io.BytesIO()
    pq.write_table(table, buffer)
    buffer.seek(0)
    s3.upload_fileobj(buffer, bucket, key)
    logger.info(f"Written {key} to s3://{bucket}/{key}")

# --- Dimension Builders ---
def build_dim_staff(staff_df, department_df):
    merged = pd.merge(
        staff_df,
        department_df[["department_id", "department_name", "location"]],
        on="department_id",
        how="left"
    )
    return merged[[
        "staff_id", "first_name", "last_name",
        "department_name", "location", "email_address"
    ]].drop_duplicates()

def build_dim_location(address_df):
    return address_df.rename(columns={"address_id": "location_id"})[[
        "location_id", "address_line_1", "address_line_2", "district",
        "city", "postal_code", "country", "phone"
    ]].drop_duplicates()

def build_dim_currency(currency_df):
    currency_name_map = {
        "GBP": "British Pound",
        "EUR": "Euro",
        "USD": "US Dollar"
    }
    currency_df["currency_name"] = currency_df["currency_code"].map(currency_name_map)
    currency_df["currency_name"] = currency_df["currency_name"].fillna(currency_df["currency_code"])
    return currency_df[["currency_id", "currency_code", "currency_name"]].drop_duplicates()

def build_dim_design(design_df):
    return design_df[["design_id", "design_name", "file_location", "file_name"]].drop_duplicates()

def build_dim_counterparty(counterparty_df, address_df):
    merged = pd.merge(
        counterparty_df,
        address_df,
        left_on="legal_address_id",
        right_on="address_id",
        how="left"
    )
    return merged[[
        "counterparty_id", "counterparty_legal_name",
        "address_line_1", "address_line_2", "district", "city",
        "postal_code", "country", "phone"
    ]].rename(columns={
        "address_line_1": "counterparty_legal_address_line_1",
        "address_line_2": "counterparty_legal_address_line_2",
        "district": "counterparty_legal_district",
        "city": "counterparty_legal_city",
        "postal_code": "counterparty_legal_postal_code",
        "country": "counterparty_legal_country",
        "phone": "counterparty_legal_phone_number"
    }).drop_duplicates()

def build_dim_date(sales_df):
    date_cols = ["created_at", "agreed_delivery_date", "agreed_payment_date"]
    all_dates = pd.Series(pd.to_datetime(sales_df[date_cols].values.ravel(), errors="coerce"))
    all_dates = all_dates.dropna().drop_duplicates()
    date_df = pd.DataFrame({
        "date_id": all_dates.dt.date,
        "year": all_dates.dt.year,
        "month": all_dates.dt.month,
        "day": all_dates.dt.day,
        "day_of_week": all_dates.dt.weekday + 1,
        "day_name": all_dates.dt.day_name(),
        "month_name": all_dates.dt.month_name(),
        "quarter": all_dates.dt.quarter
    }).drop_duplicates()
    return date_df

def build_fact_sales_order(sales_df):
    sales_df = sales_df.copy()
    sales_df["created_date"] = pd.to_datetime(sales_df["created_at"], errors="coerce").dt.date
    sales_df["last_updated_date"] = pd.to_datetime(sales_df["last_updated"], errors="coerce").dt.date
    sales_df["agreed_payment_date"] = pd.to_datetime(sales_df["agreed_payment_date"], errors="coerce").dt.date
    sales_df["agreed_delivery_date"] = pd.to_datetime(sales_df["agreed_delivery_date"], errors="coerce").dt.date
    sales_df["unit_price"] = pd.to_numeric(sales_df["unit_price"], errors="coerce").round(2)

    return sales_df[[
        "sales_order_id", "created_date",
        "last_updated_date", "staff_id", "counterparty_id",
        "units_sold", "unit_price", "currency_id", "design_id",
        "agreed_payment_date", "agreed_delivery_date",
        "agreed_delivery_location_id"
    ]].drop_duplicates()

def get_default_timestamps(table_names):
    return {table: "1970-01-01T00:00:00Z" for table in table_names}


def read_last_processed_times(table_names):
    try:
        obj = s3.get_object(Bucket=TARGET_BUCKET, Key=TIMESTAMP_FILE)
        return json.loads(obj["Body"].read().decode("utf-8"))
    except s3.exceptions.NoSuchKey:
        logger.warning("No last_processed.json found. Starting from epoch.")
        return get_default_timestamps(table_names)


def write_last_processed_times(timestamps):
    s3.put_object(
        Bucket=TARGET_BUCKET,
        Key=TIMESTAMP_FILE,
        Body=json.dumps(timestamps),
        ContentType="application/json"
    )


def transform_and_load():
    logger.info("Starting transformation Lambda")
    prefix = ""

    table_names = ["staff", "department", "address", "currency", "design", "counterparty", "sales_order"]

    last_processed = read_last_processed_times(table_names)
    updated_processed = last_processed.copy()
    dfs = {}

    for table in table_names:
        matched_files = list_matching_files(SOURCE_BUCKET, prefix, [table])
        if not matched_files:
            logger.warning(f"No files found for table: {table}")
            continue

        df = pd.concat([read_csv_from_s3(SOURCE_BUCKET, key) for key in matched_files], ignore_index=True)

        if "last_updated" in df.columns:
            # Convert both to datetime with timezone info
            df["last_updated"] = pd.to_datetime(df["last_updated"], errors="coerce", utc=True)
            last_time = pd.to_datetime(last_processed.get(table, "1970-01-01T00:00:00Z"), utc=True)
            
            # Filter for records newer than last processed time
            df = df[df["last_updated"] > last_time]

            if not df.empty:
                new_max = df["last_updated"].max()
                updated_processed[table] = new_max.isoformat()

        if df.empty:
            logger.info(f"No new data for table: {table}")
            continue  # This was missing - need to skip to next table

        dfs[table] = df

    if not dfs:
        logger.info("No new data to process")
        return  # Added return statement

    # Build and write transformed tables
    if "staff" in dfs and "department" in dfs:
        write_parquet_to_s3(build_dim_staff(dfs["staff"], dfs["department"]), TARGET_BUCKET, f"{year}/{month}/{day}/dim_staff_{timestamp}.parquet")

    if "address" in dfs:
        write_parquet_to_s3(build_dim_location(dfs["address"]), TARGET_BUCKET, f"{year}/{month}/{day}/dim_location_{timestamp}.parquet")

    if "currency" in dfs:
        write_parquet_to_s3(build_dim_currency(dfs["currency"]), TARGET_BUCKET, f"{year}/{month}/{day}/dim_currency_{timestamp}.parquet")

    if "design" in dfs:
        write_parquet_to_s3(build_dim_design(dfs["design"]), TARGET_BUCKET, f"{year}/{month}/{day}/dim_design_{timestamp}.parquet")

    if "counterparty" in dfs and "address" in dfs:
        write_parquet_to_s3(build_dim_counterparty(dfs["counterparty"], dfs["address"]), TARGET_BUCKET, f"{year}/{month}/{day}/dim_counterparty_{timestamp}.parquet")

    if "sales_order" in dfs:
        write_parquet_to_s3(build_fact_sales_order(dfs["sales_order"]), TARGET_BUCKET, f"{year}/{month}/{day}/fact_sales_order_{timestamp}.parquet")
        write_parquet_to_s3(build_dim_date(dfs["sales_order"]), TARGET_BUCKET, f"{year}/{month}/{day}/dim_date_{timestamp}.parquet")

    write_last_processed_times(updated_processed)
    logger.info("Transformation complete")

def lambda_handler(event, context):
    try:
        transform_and_load()
        return {"status": "success"}
    except Exception as e:
        logger.error(f"Transform Lambda failed: {e}")
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    lambda_handler("hi", "hi")