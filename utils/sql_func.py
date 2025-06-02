def select_all_query(conn, table_name):
    """sql query that gathers every row of the record from a table
    parameter:
        conn -- connection to the database
        table_name -- the table name you want to gather
    return:
        list of data"""
    try:
        return conn.run(f"SELECT * FROM {table_name}")
    
    except Exception as err:
        raise err
    
