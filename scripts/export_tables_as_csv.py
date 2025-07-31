import sqlite3
import pandas as pd

DB_NAME = 'bps_database.db'
conn = sqlite3.connect(DB_NAME)

cursor = conn.cursor()

cursor.execute("SELECT * FROM sqlite_master WHERE type='table';")
tables = cursor.fetchall()

for table in tables:
    table_name = table[1]
    cursor.execute(f"SELECT * FROM {table_name};")
    data = cursor.fetchall()
    df = pd.DataFrame(data, columns=[description[0] for description in cursor.description])
    df.to_csv(f"new_tables/{table_name}.csv", index=False)
