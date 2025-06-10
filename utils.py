import boto3

s3 = boto3.client("s3")


def list_matching_files(bucket, prefix, table_names):
    """
    List all S3 keys under the prefix that match any of the given table name keywords.
    """
    matching_files = []
    paginator = s3.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket, Prefix=prefix)

    for page in pages:
        for obj in page.get("Contents", []):
            key = obj["Key"]
            if key.endswith(".csv.gz") and any(name in key for name in table_names):
                matching_files.append(key)

    return matching_files