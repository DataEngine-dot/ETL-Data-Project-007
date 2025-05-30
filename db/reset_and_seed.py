# file: reset_and_seed.py

import subprocess
import os
from pg8000.native import Connection
from dotenv import load_dotenv

load_dotenv(dotenv_path=".env.test")

DB_NAME = "mock_totesys"
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", 5432))
CSV_DIR = "./mock_export"
SCHEMA_FILE = "./schema.sql"

TABLES = [
    "address",
    "counterparty",
    "currency",
    "department",
    "design",
    "payment_type",
    "purchase_order",
    "staff",
    "payment",
    "transaction",
    "sales_order",
]

def run_shell(cmd):
    print(f"Running shell: {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        raise RuntimeError(result.stderr)
    print("✅ Done.")

def reset_database():
    run_shell(f'psql -U {DB_USER} -c "DROP DATABASE IF EXISTS {DB_NAME};"')
    run_shell(f'psql -U {DB_USER} -c "CREATE DATABASE {DB_NAME};"')

def load_schema():
    run_shell(f'psql -U {DB_USER} -d {DB_NAME} -f {SCHEMA_FILE}')

def load_csv_data():
    print("Connecting with pg8000...")
    conn = Connection(
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        host=DB_HOST,
        port=DB_PORT
    )
    
    for table in TABLES:
        csv_path = os.path.join(CSV_DIR, f"{table}.csv")
        if not os.path.exists(csv_path):
            print(f"Skipping {table} (missing CSV)")
            continue

        try:
            print(f"Loading {table}...")
            with open(csv_path, "r") as f:
                csv_content = f.read()
                conn.run(f"COPY {table} FROM STDIN WITH CSV HEADER", stream=csv_content)
        except Exception as e:
            print(f"Error loading {table}: {e}")
    
    conn.close()

if __name__ == "__main__":
    reset_database()
    load_schema()
    load_csv_data()
    print("Test DB ready!")
