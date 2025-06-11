import json
import os
import boto3
import csv
import io
from datetime import datetime

s3 = boto3.client('s3')

def transform_dim_counterparty(counterparty_rows, address_rows):
    # Convert addresses to a dict for quick lookup
    address_map = {a['address_id']: a for a in address_rows}
    output = []
    for row in counterparty_rows:
        addr = address_map.get(row['legal_address_id'])
        output.append({
            'counterparty_id': row['counterparty_id'],
            'counterparty_legal_name': row['counterparty_legal_name'],
            'counterparty_legal_address_line_1': addr['address_line_1'] if addr else None,
            'counterparty_legal_address_line_2': addr['address_line_2'] if addr else None,
            'counterparty_legal_district': addr['district'] if addr else None,
            'counterparty_legal_city': addr['city'] if addr else None,
            'counterparty_legal_postal_code': addr['postal_code'] if addr else None,
            'counterparty_legal_country': addr['country'] if addr else None,
            'counterparty_legal_phone_number': addr['phone'] if addr else None
        })
    return output

def transform_dim_currency(rows):
    # The warehouse expects currency_id, currency_code, currency_name
    for r in rows:
        if 'currency_name' not in r:
            r['currency_name'] = None
    return [{k: r[k] for k in ['currency_id', 'currency_code', 'currency_name']} for r in rows]

def transform_dim_design(rows):
    return [{k: r[k] for k in ['design_id', 'design_name', 'file_location', 'file_name']} for r in rows]

def transform_dim_location(address_rows):
    return [{
        'location_id': r['address_id'],
        'address_line_1': r['address_line_1'],
        'address_line_2': r['address_line_2'],
        'district': r['district'],
        'city': r['city'],
        'postal_code': r['postal_code'],
        'country': r['country'],
        'phone': r['phone']
    } for r in address_rows]

def transform_dim_payment_type(rows):
    return [{k: r[k] for k in ['payment_type_id', 'payment_type_name']} for r in rows]

def transform_dim_staff(rows):
    # Warehouse expects: staff_id, first_name, last_name, department_name, location, email_address
    for r in rows:
        r['department_name'] = None   # If you need to join, add it here
        r['location'] = None
    return [{k: r[k] for k in ['staff_id', 'first_name', 'last_name', 'department_name', 'location', 'email_address']} for r in rows]

def transform_dim_transaction(rows):
    return [{k: r[k] for k in ['transaction_id', 'transaction_type', 'sales_order_id', 'purchase_order_id']} for r in rows]

def transform_fact_payment(rows):
    # Many warehouse fields must be constructed or set to None (not present in source)
    out = []
    for r in rows:
        out.append({
            'payment_record_id': None,
            'payment_id': r['payment_id'],
            'created_date': None,
            'created_time': None,
            'last_updated_date': None,
            'last_updated_time': None,
            'transaction_id': r['transaction_id'],
            'counterparty_id': r['counterparty_id'],
            'payment_amount': r['payment_amount'],
            'currency_id': r['currency_id'],
            'payment_type_id': r['payment_type_id'],
            'paid': r['paid'],
            'payment_date': r['payment_date']
        })
    return out

def transform_fact_purchase_order(rows):
    out = []
    for r in rows:
        out.append({
            'purchase_record_id': None,
            'purchase_order_id': r['purchase_order_id'],
            'created_date': None,
            'created_time': None,
            'last_updated_date': None,
            'last_updated_time': None,
            'staff_id': r['staff_id'],
            'counterparty_id': r['counterparty_id'],
            'item_code': r['item_code'],
            'item_quantity': r['item_quantity'],
            'item_unit_price': r['item_unit_price'],
            'currency_id': r['currency_id'],
            'agreed_delivery_date': r['agreed_delivery_date'],
            'agreed_payment_date': r['agreed_payment_date'],
            'agreed_delivery_location_id': r['agreed_delivery_location_id']
        })
    return out

def transform_fact_sales_order(rows):
    out = []
    for r in rows:
        out.append({
            'sales_record_id': None,
            'sales_order_id': r['sales_order_id'],
            'created_date': None,
            'created_time': None,
            'last_updated_date': None,
            'last_updated_time': None,
            'sales_staff_id': r['staff_id'],
            'counterparty_id': r['counterparty_id'],
            'units_sold': r['units_sold'],
            'unit_price': r['unit_price'],
            'currency_id': r['currency_id'],
            'design_id': r['design_id'],
            'agreed_payment_date': r['agreed_payment_date'],
            'agreed_delivery_date': r['agreed_delivery_date'],
            'agreed_delivery_location_id': r['agreed_delivery_location_id']
        })
    return out

# Table transformation registry
TRANSFORM_FUNCTIONS = {
    'dim_counterparty': transform_dim_counterparty,
    'dim_currency': transform_dim_currency,
    'dim_design': transform_dim_design,
    'dim_location': transform_dim_location,
    'dim_payment_type': transform_dim_payment_type,
    'dim_staff': transform_dim_staff,
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
    writer.writerows(rows)
    s3.put_object(Bucket=bucket, Key=key, Body=buf.getvalue().encode("utf-8"), ContentType='text/csv')

def lambda_handler(event, context):
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

    # Preload shared sources (for joins)
    address_rows = read_csv_from_s3(input_bucket, s3_keys_per_table['address'][0]) if 'address' in s3_keys_per_table else []

    for table, s3_keys in s3_keys_per_table.items():
        output_keys[table] = []
        table_name = table
        for s3_key in s3_keys:
            # 1. Read source rows
            rows = read_csv_from_s3(input_bucket, s3_key)

            # 2. Transform according to the target table
            if table_name == 'dim_counterparty':
                # Needs both counterparty and address
                transformed = transform_dim_counterparty(rows, address_rows)
            elif table_name == 'dim_location':
                transformed = transform_dim_location(address_rows)
            else:
                transform_fn = TRANSFORM_FUNCTIONS.get(table_name)
                if transform_fn:
                    transformed = transform_fn(rows)
                else:
                    transformed = rows

            total_records += len(transformed)

            # 3. Write result to S3
            if transformed:
                columns = list(transformed[0].keys())
                output_key = f"{output_prefix}/{table_name}_result_{now}.csv"
                write_csv_to_s3(output_bucket, output_key, transformed, columns)
                output_keys[table].append(output_key)

    return {
        "status": "success",
        "output_s3_keys": output_keys,
        "num_records": total_records
    }

handler = lambda_handler
