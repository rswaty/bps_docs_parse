import sqlite3
from pathlib import Path

import pandas as pd

DB_NAME = "bps_database.db"
OUTPUT_DIRS = ["new_tables", "outputs"]

conn = sqlite3.connect(DB_NAME)
tables = pd.read_sql("SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name", conn)

for folder in OUTPUT_DIRS:
    Path(folder).mkdir(exist_ok=True)

for table_name in tables["name"]:
    frame = pd.read_sql(f"SELECT * FROM {table_name}", conn)
    for folder in OUTPUT_DIRS:
        frame.to_csv(Path(folder) / f"{table_name}.csv", index=False)

conn.close()
