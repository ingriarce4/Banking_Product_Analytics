"""Load the synthetic CSV data into banking_analytics.db using SQLite."""
from pathlib import Path
import sqlite3
import pandas as pd

ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "banking_analytics.db"

with sqlite3.connect(DB_PATH) as conn:
    conn.executescript((ROOT / "sql" / "01_schema.sql").read_text(encoding="utf-8"))
    for table in ("users", "payments", "events", "experiment_assignments"):
        frame = pd.read_csv(ROOT / "data" / f"{table}.csv")
        # SQLite schema exists already; append rows using pandas.
        frame.to_sql(table, conn, if_exists="append", index=False)
    print(f"Database created: {DB_PATH}")
    print("Tables loaded: users, payments, events, experiment_assignments")
