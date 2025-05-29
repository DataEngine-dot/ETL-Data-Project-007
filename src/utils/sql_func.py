def select_all_query(conn, table_name):
    try:
        # return conn.run(f"""SELECT * FROM {table_name} 
        #                 WHERE last_updated > now() - INTERVAL '30 minutes'""")
        return conn.run(f"SELECT now(), last_updated FROM {table_name};")
    except Exception as err:
        raise err
    
    # f"SELECT last_updated FROM {table} WHERE "
    #         f"last_updated > now() - INTERVAL '{interval}' LIMIT 1;"