import os
import json
import pg8000
import boto3
import csv
import io

s3 = boto3.client("s3")

def clean_row(row):
    # Replace all empty string values with None
    return [None if v == "" else v for v in row.values()]

def handler(event, context):
    print("[Warehouse Loader] Event received:", json.dumps(event))
    required_env_vars = [
        "WAREHOUSE_DB_USER", "WAREHOUSE_DB_PASSWORD", "WAREHOUSE_DB_HOST",
        "WAREHOUSE_DB_NAME", "WAREHOUSE_DB_PORT", "S3_BUCKET"
    ]
    try:
        # Check required environment variables
        for var in required_env_vars:
            value = os.environ.get(var)
            print(f"{var}: {value!r}")
            if not value:
                raise RuntimeError(f"Missing required env var: {var}")

        # Connect to the database
        conn = pg8000.connect(
            user=os.environ['WAREHOUSE_DB_USER'],
            password=os.environ['WAREHOUSE_DB_PASSWORD'],
            host=os.environ['WAREHOUSE_DB_HOST'],
            database=os.environ['WAREHOUSE_DB_NAME'],
            port=int(os.environ.get("WAREHOUSE_DB_PORT", 5432))
        )
        print("DB connection established")
        cursor = conn.cursor()

        output_s3_keys = event.get("output_s3_keys", {})
        s3_bucket = os.environ["S3_BUCKET"]
        loaded_tables = set()

        # Loop directly over warehouse table names and S3 keys
        for warehouse_table, s3_keys in output_s3_keys.items():
            for s3_key in s3_keys:
                print(f"Loading {s3_key} into {warehouse_table}")
                response = s3.get_object(Bucket=s3_bucket, Key=s3_key)
                csv_content = response['Body'].read().decode('utf-8')
                reader = csv.DictReader(io.StringIO(csv_content))
                rows = list(reader)
                if not rows:
                    print(f"[INFO] No rows found in {s3_key}, skipping.")
                    continue

                columns = list(rows[0].keys())
                insert_sql = f"INSERT INTO {warehouse_table} ({', '.join(columns)}) VALUES ({', '.join(['%s']*len(columns))})"
                try:
                    for row in rows:
                        try:
                            cursor.execute(insert_sql, clean_row(row))
                        except Exception as row_error:
                            print(f"[ERROR] Failed to insert row into {warehouse_table}: {row_error}")
                            conn.rollback()
                            break
                    else:
                        conn.commit()
                        loaded_tables.add(warehouse_table)
                except Exception as file_error:
                    print(f"[FILE ERROR] Error processing file {s3_key}: {file_error}")
                    conn.rollback()
                    continue

        cursor.close()
        conn.close()
        print("DB connection closed")

        return {
            "statusCode": 200,
            "body": json.dumps(f"Warehouse load completed for tables: {sorted(list(loaded_tables))}")
        }
    except Exception as e:
        print("[FAIL FAST ERROR]", repr(e))
        raise
