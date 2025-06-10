import os
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
import pytest
from pathlib import Path

# --- Import transformation functions ---
from transform import (
    build_dim_staff, build_dim_location, build_dim_currency,
    build_dim_design, build_dim_counterparty,
    build_dim_date, build_fact_sales_order
)

SOURCE_DIR = Path("./db/mock_export")
OUTPUT_DIR = Path("./processed")
OUTPUT_DIR.mkdir(exist_ok=True)

# --- Helper functions for local testing ---
def read_csv(filename):
    return pd.read_csv(SOURCE_DIR / filename)

def write_parquet(df, filename):
    table = pa.Table.from_pandas(df)
    pq.write_table(table, OUTPUT_DIR / filename)

def parquet_exists_and_not_empty(filename):
    path = OUTPUT_DIR / filename
    return path.exists() and pq.read_table(path).num_rows > 0

# --- Load all required data upfront (for reuse in tests) ---
staff_df = read_csv("staff.csv")
department_df = read_csv("department.csv")
address_df = read_csv("address.csv")
currency_df = read_csv("currency.csv")
design_df = read_csv("design.csv")
counterparty_df = read_csv("counterparty.csv")
sales_order_df = read_csv("sales_order.csv")

# --- Test Cases ---
def test_dim_staff():
    df = build_dim_staff(staff_df, department_df)
    write_parquet(df, "dim_staff.parquet")
    assert parquet_exists_and_not_empty("dim_staff.parquet")

def test_dim_location():
    df = build_dim_location(address_df)
    write_parquet(df, "dim_location.parquet")
    assert parquet_exists_and_not_empty("dim_location.parquet")

def test_dim_currency():
    df = build_dim_currency(currency_df)
    write_parquet(df, "dim_currency.parquet")
    assert "currency_name" in df.columns
    assert parquet_exists_and_not_empty("dim_currency.parquet")

def test_dim_design():
    df = build_dim_design(design_df)
    write_parquet(df, "dim_design.parquet")
    assert parquet_exists_and_not_empty("dim_design.parquet")

def test_dim_counterparty():
    df = build_dim_counterparty(counterparty_df, address_df)
    write_parquet(df, "dim_counterparty.parquet")
    assert "counterparty_legal_address_line_1" in df.columns
    assert parquet_exists_and_not_empty("dim_counterparty.parquet")

def test_dim_date():
    df = build_dim_date(sales_order_df)
    write_parquet(df, "dim_date.parquet")
    assert "date_id" in df.columns
    assert parquet_exists_and_not_empty("dim_date.parquet")

def test_fact_sales_order():
    df = build_fact_sales_order(sales_order_df)
    write_parquet(df, "fact_sales_order.parquet")
    assert "sales_order_id" in df.columns
    assert parquet_exists_and_not_empty("fact_sales_order.parquet")