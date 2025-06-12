import json
import os
import boto3
import csv
import io
from datetime import datetime

s3 = boto3.client('s3')

# Map raw pipeline names to warehouse table names
RAW_TO_WAREHOUSE = {
    "sales_order": "fact_sales_order",
    "purchase_order": "fact_purchase_order",
    "payment": "fact_payment",
    "design": "dim_design",
    "currency": "dim_currency",
    "staff": "dim_staff",
    "counterparty": "dim_counterparty",
    "department": "dim_department",
    "address": "dim_location",
    "payment_type": "dim_payment_type",
    "transaction": "dim_transaction"
}

# Warehouse column definitions
WAREHOUSE_COLUMNS = {
    'dim_counterparty': [
        'counterparty_id', 'counterparty_legal_name',
        'counterparty_legal_address_line_1', 'counterparty_legal_address_line_2',
        'counterparty_legal_district', 'counterparty_legal_city',
        'counterparty_legal_postal_code', 'counterparty_legal_country', 'counterparty_legal_phone_number'
    ],
    'dim_currency': ['currency_id', 'currency_code', 'currency_name'],
    'dim_design': ['design_id', 'design_name', 'file_location', 'file_name'],
    'dim_location': ['location_id', 'address_line_1', 'address_line_2', 'district', 'city', 'postal_code', 'country', 'phone'],
    'dim_payment_type': ['payment_type_id', 'payment_type_name'],
    'dim_staff': ['staff_id', 'first_name', 'last_name', 'department_name', 'location', 'email_address'],
    'dim_department': ['department_id', 'department_name', 'location', 'manager', 'created_at', 'last_updated'],
    'dim_transaction': ['transaction_id', 'transaction_type', 'sales_order_id', 'purchase_order_id'],
    'fact_payment': [
        'payment_record_id', 'payment_id', 'created_date', 'created_time',
        'last_updated_date', 'last_updated_time', 'transaction_id', 'counterparty_id',
        'payment_amount', 'currency_id', 'payment_type_id', 'paid', 'payment_date'
    ],
    'fact_purchase_order': [
        'purchase_record_id', 'purchase_order_id', 'created_date', 'created_time',
        'last_updated_date', 'last_updated_time', 'staff_id', 'counterparty_id',
        'item_code', 'item_quantity', 'item_unit_price', 'currency_id',
        'agreed_delivery_date', 'agreed_payment_date', 'agreed_delivery_location_id'
    ],
    'fact_sales_order': [
        'sales_record_id', 'sales_order_id', 'created_date', 'created_time',
        'last_updated_date', 'last_updated_time', 'sales_staff_id', 'counterparty_id',
        'units_sold', 'unit_price', 'currency_id', 'design_id',
        'agreed_payment_date', 'agreed_delivery_date', 'agreed_delivery_location_id'
    ]
}

# ==== Transform functions as before ====

def transform_dim_counterparty(counterparty_rows, address_rows):
    address_map = {a['address_id']: a for a in address_rows}
    output = []
    for row in counterparty_rows:
        addr = address_map.get(row['legal_address_id'], {})
        output.append({
            'counterparty_id': row['counterparty_id'],
            'counterparty_legal_name': row['counterparty_legal_name'],
            'counterparty_legal_address_line_1': addr.get('address_line_1', ''),
            'counterparty_legal_address_line_2': addr.get('address_line_2', ''),
            'counterparty_legal_district': addr.get('district', ''),
            'counterparty_legal_city': addr.get('city', ''),
            'counterparty_legal_postal_code': addr.get('postal_code', ''),
            'counterparty_legal_country': addr.get('country', ''),
            'counterparty_legal_phone_number': addr.get('phone', ''),
        })
    return output

def transform_dim_location(address_rows):
    output = []
    for row in address_rows:
        output.append({
            'location_id': row.get('address_id', ''),
            'address_line_1': row.get('address_line_1', ''),
            'address_line_2': row.get('address_line_2', ''),
            'district': row.get('district', ''),
            'city': row.get('city', ''),
            'postal_code': row.get('postal_code', ''),
            'country': row.get('country', ''),
            'phone': row.get('phone', ''),
        })
    return output

def transform_dim_staff(staff_rows, department_rows):
    department_map = {d['department_id']: d for d in department_rows}
    output = []
    for row in staff_rows:
        dept = department_map.get(row.get('department_id'), {})
        output.append({
            'staff_id': row.get('staff_id', ''),
            'first_name': row.get('first_name', ''),
            'last_name': row.get('last_name', ''),
            'department_name': dept.get('department_name', ''),
            'location': dept.get('location', ''),
            'email_address': row.get('email_address', ''),
        })
    return output

def identity(rows):
    return rows

def transform_dim_currency(rows): return rows
def transform_dim_design(rows): return rows
def transform_dim_payment_type(rows): return rows
def transform_dim_department(rows): return rows
def transform_dim_transaction(rows): return rows
def transform_fact_payment(rows): return rows
def transform_fact_purchase_order(rows): return rows
def transform_fact_sales_order(rows): return rows

# Map warehouse table to the transform function
TRANSFORM_FUNCTIONS = {
    'dim_counterparty': transform_dim_counterparty,
    'dim_currency': transform_dim_currency,
    'dim_design': transform_dim_design,
    'dim_location': transform_dim_location,
    'dim_payment_type': transform_dim_payment_type,
    'dim_staff': transform_dim_staff,
    'dim_department': transform_dim_department,
    'dim_transaction': transform_dim_transaction,
    'fact_payment': transform_fact_payment,
    'fact_purchase_order': transform_fact_purchase_order,
    'fact_sales_order': transform_fact_sales_order,
}

def read_csv_from_s3(bucket, key):
    response = s3.get_object(Bucket=bucket, Key=key)
    content = response['Body'].read().decode('utf-8')
    return list(csv.DictReader(io.StringIO(content)))

def write_csv_to_s3(bucket, key, rows, columns):
    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=columns)
    writer.writeheader()
    for row in rows:
        writer.writerow({k: row.get(k, "") for k in columns})
    s3.put_object(Bucket=bucket, Key=key, Body=buf.getvalue().encode("utf-8"), ContentType='text/csv')

def lambda_handler(event, context):
    print("TRANSFORMATION EVENT:", json.dumps(event))
    s3_keys_per_table = event.get("s3_keys")
    if not s3_keys_per_table:
        return {
            "status": "skipped",
            "output_s3_keys": {},
            "num_records": 0,
            "message": "No data to transform (empty s3_keys from ingestion)"
        }

    input_bucket = os.environ.get('INPUT_BUCKET')
    output_bucket = os.environ.get('OUTPUT_BUCKET', input_bucket)
    now = datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    output_prefix = "processed"
    output_keys = {}
    total_records = 0

    # Shared data for joins
    address_rows = read_csv_from_s3(input_bucket, s3_keys_per_table['address'][0]) if 'address' in s3_keys_per_table else []
    department_rows = read_csv_from_s3(input_bucket, s3_keys_per_table['department'][0]) if 'department' in s3_keys_per_table else []

    for raw_table_name, s3_keys in s3_keys_per_table.items():
        warehouse_table = RAW_TO_WAREHOUSE.get(raw_table_name)
        if not warehouse_table:
            print(f"[WARN] No warehouse table mapping for {raw_table_name}, skipping.")
            continue
        output_keys.setdefault(warehouse_table, [])
        for s3_key in s3_keys:
            rows = read_csv_from_s3(input_bucket, s3_key)
            # Call the right transform function (pass in extra tables if needed)
            if warehouse_table == 'dim_counterparty':
                transformed = transform_dim_counterparty(rows, address_rows)
            elif warehouse_table == 'dim_location':
                transformed = transform_dim_location(address_rows)
            elif warehouse_table == 'dim_staff':
                transformed = transform_dim_staff(rows, department_rows)
            else:
                transform_fn = TRANSFORM_FUNCTIONS.get(warehouse_table, identity)
                transformed = transform_fn(rows)
            total_records += len(transformed)
            columns = WAREHOUSE_COLUMNS.get(warehouse_table)
            if not columns:
                print(f"[WARN] No column mapping for {warehouse_table}, skipping.")
                continue
            filtered_rows = [{k: row.get(k, "") for k in columns} for row in transformed]
            output_key = f"{output_prefix}/{warehouse_table}_result_{now}.csv"
            write_csv_to_s3(output_bucket, output_key, filtered_rows, columns)
            print(f"[INFO] Wrote {len(filtered_rows)} records to {output_key}")
            output_keys[warehouse_table].append(output_key)

    return {
        "status": "success",
        "output_s3_keys": output_keys,
        "num_records": total_records
    }

handler = lambda_handler
