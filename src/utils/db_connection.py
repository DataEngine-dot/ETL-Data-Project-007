import os
from pg8000.native import Connection
from dotenv import load_dotenv

load_dotenv()

def connect_to_db():
    return Connection(
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME"),
        host=os.getenv("DB_HOST"),
        port=int(os.getenv("DB_PORT"))
    )

if __name__ == "__main__":
    try:
        conn = connect_to_db()
        print("Connected to database!")
        conn.close()
    except Exception as e:
        print(f"Failed to connect: {e}")

