import os
from pg8000.native import Connection
from dotenv import load_dotenv

def connect_to_test_db():
    
    load_dotenv(dotenv_path=".env.test")

    return Connection(
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME"),
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", 5432)),
    )
