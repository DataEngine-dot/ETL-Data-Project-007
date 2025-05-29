import os
from pg8000.native import Connection
import boto3
from botocore.exceptions import ClientError
import json



def get_secrets(secretname="TotesysDatabase"):
    """This functions gets the credentials for totesys database from 
    secret manager using boto3
    returns - dict"""
    try:
        session = boto3.Session(profile_name="test-account")
        sm_client = session.client("secretsmanager")
        response = sm_client.get_secret_value(SecretId=secretname)
    except ClientError as e:
        raise e
    return json.loads(response['SecretString'])


def connect_to_db(credentials):
    """This function connects to the database. 
    parameter - dict (we get this from boto3 secret manager)"""
    return Connection(
        user=credentials["DB_USER"],
        password=credentials["DB_PASSWORD"],
        database=credentials["DB_NAME"],
        host=credentials["DB_HOST"],
        port=int(credentials["DB_PORT"])
    )


def close_db(db):
    db.close()


if __name__ == "__main__":
    try:
        totesys_credentials = get_secrets()
        conn = connect_to_db(totesys_credentials)
        print("Connected to database!")
        conn.close()
    except Exception as e:
        print(f"Failed to connect: {e}")



