import os
from dotenv import load_dotenv
from db.connect_to_test_db import connect_to_test_db

load_dotenv(dotenv_path=".env.test")

def test_address_table_has_rows():
    
    conn = connect_to_test_db()
    
    result = conn.run("SELECT COUNT(*) FROM address;")
    
    conn.close()
    
    count = result[0][0]
    
    assert count > 0, "No rows in 'address' table"
