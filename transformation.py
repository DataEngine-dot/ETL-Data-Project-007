import json
import os
import boto3
import csv
import io
from datetime import datetime

s3 = boto3.client('s3')

# --------- Define exact columns for each warehouse table ---------
WAREHOUSE_COLUMNS = {
    'dim_counterparty': [
        'counterparty_id', 'counterparty_legal_name',
        'counterparty_legal_address_line_1', 'counterparty_legal_address_line_2',
        'counterparty_legal_district', 'counterparty_legal_city',
        'counterparty_legal_postal_code', 'counterparty_legal_country', 'counterparty_legal_phone_number'
    ],
    'dim_currency': [
        'currency_id', 'currency_code', 'currency_name'
    ],
    'dim_design': [
        'design_id', 'design_name', 'file_location', 'file_name'
    ],
    'dim_location': [
        'location_id', 'address_line_1', 'address_line_2', 'district',
        'city', 'postal_code', 'country', 'phone'
    ],
    'dim_payment_type': [
        'payment_type_id', 'payment_type_name'
    ],
    'dim_staff': [
        'staff_id', 'first_name', 'last_name', 'department_name', 'location', 'email_address'
    ],
    'dim_transaction': [
        'transaction_id', 'transaction_type', 'sales_order_id', 'purchase_order_id'
    ],
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

def split_datetime(dt_str):
    """Split a timestamp string into (YYYY-MM-DD, HH:MM:SS) or (None, None) if not valid."""
    try:
        dt = datetime.fromisoformat(dt_str.replace('T', ' '))
        return dt.date().isoformat(), dt.time().isoformat(timespec='seconds')
    except Exception:
        return None, None

def transform_dim_counterparty(counterparty_rows, address_rows):
    address_map = {int(a['address_id']): a for a in address_rows}
    output = []
    for row in counterparty_rows:
        addr = address_map.get(int(row['legal_address_id']))
        output.append({
            'counterparty_id': int(row['counterparty_id']),
            'counterparty_legal_name': row['counterparty_legal_name'],
            'counterparty_legal_address_line_1': addr['address_line_1'] if addr else None,
            'counterparty_legal_address_line_2': addr.get('address_line_2', None) if addr else None,
            'counterparty_legal_district': addr.get('district', None) if addr else None,
            'counterparty_legal_city': addr['city'] if addr else None,
            'counterparty_legal_postal_code': addr['postal_code'] if addr else None,
            'counterparty_legal_country': addr['country'] if addr else None,
            'counterparty_legal_phone_number': addr['phone'] if addr else None,
        })
    return output

def transform_dim_currency(rows):
    return [{
        'currency_id': int(r['currency_id']),
        'currency_code': r['currency_code'],
        'currency_name': r.get('currency_name', r['currency_code'])
    } for r in rows]

def transform_dim_design(rows):
    return [{
        'design_id': int(r['design_id']),
        'design_name': r['design_name'],
        'file_location': r['file_location'],
        'file_name': r['file_name'],
    } for r in rows]

def transform_dim_location(address_rows):
    return [{
        'location_id': int(r['address_id']),
        'address_line_1': r['address_line_1'],
        'address_line_2': r.get('address_line_2', None),
        'district': r.get('district', None),
        'city': r['city'],
        'postal_code': r['postal_code'],
        'country': r['country'],
        'phone': r['phone'],
    } for r in address_rows]

def transform_dim_payment_type(rows):
    return [{
        'payment_type_id': int(r['payment_type_id']),
        'payment_type_name': r['payment_type_name'],
    } for r in rows]

def transform_dim_staff(rows, department_rows):
    dept_map = {int(d['department_id']): d for d in department_rows}
    out = []
    for r in rows:
        dept = dept_map.get(int(r['department_id']))
        out.append({
            'staff_id': int(r['staff_id']),
            'first_name': r['first_name'],
            'last_name': r['last_name'],
            'department_name': dept['department_name'] if dept else None,
            'location': dept['location'] if dept else None,
            'email_address': r['email_address'],
        })
    return out

def transform_dim_transaction(rows):
    return [{
        'transaction_id': int(r['transaction_id']),
        'transaction_type': r['transaction_type'],
        'sales_order_id': int(r['sales_order_id']) if r['sales_order_id'] else None,
        'purchase_order_id': int(r['purchase_order_id']) if r['purchase_order_id'] else None,
    } for r in rows]

def transform_fact_payment(rows):
    out = []
    for r in rows:
        created_date, created_time = split_datetime(r['created_at'])
        last_updated_date, last_updated_time = split_datetime(r['last_updated'])
        out.append({
            'payment_record_id': None,  # Auto-increment in warehouse
            'payment_id': int(r['payment_id']),
            'created_date': created_date,
            'created_time': created_time,
            'last_updated_date': last_updated_date,
            'last_updated_time': last_updated_time,
            'transaction_id': int(r['transaction_id']),
            'counterparty_id': int(r['counterparty_id']),
            'payment_amount': float(r['payment_amount']),
            'currency_id': int(r['currency_id']),
            'payment_type_id': int(r['payment_type_id']),
            'paid': r['paid'].lower() in ('true', '1', 't', 'yes') if isinstance(r['paid'], str) else bool(r['paid']),
            'payment_date': r['payment_date'],
        })
    return out

def transform_fact_purchase_order(rows):
    out = []
    for r in rows:
        created_date, created_time = split_datetime(r['created_at'])
        last_updated_date, last_updated_time = split_datetime(r['last_updated'])
        out.append({
            'purchase_record_id': None,
            'purchase_order_id': int(r['purchase_order_id']),
            'created_date': created_date,
            'created_time': created_time,
            'last_updated_date': last_updated_date,
            'last_updated_time': last_updated_time,
            'staff_id': int(r['staff_id']),
            'counterparty_id': int(r['counterparty_id']),
            'item_code': r['item_code'],
            'item_quantity': int(r['item_quantity']),
            'item_unit_price': float(r['item_unit_price']),
            'currency_id': int(r['currency_id']),
            'agreed_delivery_date': r['agreed_delivery_date'],
            'agreed_payment_date': r['agreed_payment_date'],
            'agreed_delivery_location_id': int(r['agreed_delivery_location_id']),
        })
    return out

def transform_fact_sales_order(rows):
    out = []
    for r in rows:
        created_date, created_time = split_datetime(r['created_at'])
        last_updated_date, last_updated_time = split_datetime(r['last_updated'])
        out.append({
            'sales_record_id': None,
            'sales_order_id': int(r['sales_order_id']),
            'created_date': created_date,
            'created_time': created_time,
            'last_updated_date': last_updated_date,
            'last_updated_time': last_updated_time,
            'sales_staff_id': int(r['staff_id']),
            'counterparty_id': int(r['counterparty_id']),
            'units_sold': int(r['units_sold']),
            'unit_price': float(r['unit_price']),
            'currency_id': int(r['currency_id']),
            'design_id': int(r['design_id']),
            'agreed_payment_date': r['agreed_payment_date'],
            'agreed_delivery_date': r['agreed_delivery_date'],
            'agreed_delivery_location_id': int(r['agreed_delivery_location_id']),
        })
    return out

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
    """Read CSV from S3 and return as list of dicts."""
    response = s3.get_object(Bucket=bucket, Key=key)
    content = response['Body'].read().decode('utf-8')
    return list(csv.DictReader(io.StringIO(content)))

def write_csv_to_s3(bucket, key, rows, columns):
    """Write list of dicts as CSV to S3 with explicit column ordering (all extras are stripped)."""
    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=columns)
    writer.writeheader()
    writer.writerows([{k: row.get(k) for k in columns} for row in rows])
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

    # Preload shared sources for joins
    address_rows = read_csv_from_s3(input_bucket, s3_keys_per_table['address'][0]) if 'address' in s3_keys_per_table else []
    department_rows = read_csv_from_s3(input_bucket, s3_keys_per_table['department'][0]) if 'department' in s3_keys_per_table else []

    for table, s3_keys in s3_keys_per_table.items():
        output_keys[table] = []
        table_name = table
        for s3_key in s3_keys:
            # 1. Read source rows
            rows = read_csv_from_s3(input_bucket, s3_key)

            # 2. Transform according to the target warehouse table
            if table_name == 'dim_counterparty':
                transformed = transform_dim_counterparty(rows, address_rows)
            elif table_name == 'dim_location':
                transformed = transform_dim_location(address_rows)
            elif table_name == 'dim_staff':
                transformed = transform_dim_staff(rows, department_rows)
            else:
                transform_fn = TRANSFORM_FUNCTIONS.get(table_name)
                if transform_fn:
                    transformed = transform_fn(rows)
                else:
                    transformed = rows

            total_records += len(transformed)

            # 3. Write result to S3, columns in correct warehouse order
            columns = WAREHOUSE_COLUMNS.get(table_name)
            if filtered_rows := [{k: row.get(k) for k in columns} for row in transformed if columns]:
                output_key = f"{output_prefix}/{table_name}_result_{now}.csv"
                write_csv_to_s3(output_bucket, output_key, filtered_rows, columns)
                output_keys[table].append(output_key)

    return {
        "status": "success",
        "output_s3_keys": output_keys,
        "num_records": total_records
    }

handler = lambda_handler
