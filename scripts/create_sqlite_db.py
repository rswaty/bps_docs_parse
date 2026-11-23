import sqlite3
import pandas as pd

DB_NAME = "bps_database.db"
TABLES = [
    "bps_indicators",
    "deterministic",
    "fire_frequency",
    "modelers",
    "probabilistic",
    "ref_con_long",
    "ref_con_modified",
    "sclass_species",
    "scls_descriptions",
    "text_df",
]

pd.options.mode.copy_on_write = True

BLANK_TOKENS = {"", "none", "na", "n/a", "many"}


def blank_token(value):
    if pd.isna(value):
        return ""
    text = str(value).strip()
    if text.lower() in BLANK_TOKENS:
        return ""
    return text


def split_people(names, emails):
    """Keep a combined reviewer string unless names and emails split evenly."""
    names = blank_token(names)
    emails = blank_token(emails)
    name_parts = [part.strip() for part in names.split(",") if part.strip()] if names else []
    email_parts = [part.strip() for part in emails.split(",") if part.strip()] if emails else []
    if len(name_parts) > 1 and len(name_parts) == len(email_parts):
        return list(zip(name_parts, email_parts))
    if names or emails:
        return [(names, emails)]
    return []


def person_key(name, email):
    if "@" in email:
        return ("email", email.lower())
    if name:
        return ("name", " ".join(name.lower().split()))
    if email:
        return ("text", email.lower())
    return None


dataframes = {}
for table in TABLES:
    frame = pd.read_csv(f"tables/{table}.csv")
    frame.columns = frame.columns.str.strip()
    frame = frame.dropna(axis=1, how="all")
    dataframes[table] = frame

raw_modelers = dataframes["modelers"].copy()
id_column = "bps_model_id" if "bps_model_id" in raw_modelers.columns else "bps_model"
for column in ["modelers", "modeler_email", "reviewers", "reviewer_email"]:
    raw_modelers[column] = raw_modelers[column].map(blank_token)
raw_modelers = raw_modelers[
    raw_modelers[["modelers", "modeler_email", "reviewers", "reviewer_email"]].ne("").any(axis=1)
].copy()

people = []
links = []
person_ids = {}
for row in raw_modelers.itertuples(index=False):
    model_id = str(getattr(row, id_column)).strip()
    for role, pairs in (
        ("modeler", split_people(row.modelers, row.modeler_email)),
        ("reviewer", split_people(row.reviewers, row.reviewer_email)),
    ):
        for name, email in pairs:
            key = person_key(name, email)
            if key is None:
                continue
            if key not in person_ids:
                person_ids[key] = len(person_ids) + 1
                stored_email = email.lower() if "@" in email else email
                people.append({"modeler_id": person_ids[key], "name": name, "email": stored_email})
            links.append(
                {"bps_model_id": model_id, "modeler_id": person_ids[key], "role": role}
            )

modelers = pd.DataFrame(people).drop_duplicates(subset=["modeler_id"])
models = pd.DataFrame(links).drop_duplicates().sort_values(
    ["bps_model_id", "role", "modeler_id"]
).reset_index(drop=True)
source_models = set(raw_modelers[id_column].astype(str))
linked_models = set(models["bps_model_id"])
missing_models = sorted(source_models - linked_models)
if missing_models:
    raise SystemExit(f"Models lost their people during cleanup: {missing_models[:10]}")

dataframes["modelers"] = modelers
dataframes["models"] = models
print(f"People: {len(modelers)}. Model links: {len(models)}. Models with a person: {models['bps_model_id'].nunique()}.")

conn = sqlite3.connect(DB_NAME)
conn.execute("PRAGMA foreign_keys = OFF")
conn.execute("DROP TABLE IF EXISTS models")

dataframes["text_df"].to_sql(
    "bps_models", conn, if_exists="replace", index=False, dtype={"bps_model_id": "TEXT PRIMARY KEY"}
)
dataframes["modelers"].to_sql(
    "modelers", conn, if_exists="replace", index=False, dtype={"modeler_id": "INTEGER PRIMARY KEY"}
)

conn.execute("DROP TABLE IF EXISTS models")
conn.execute(
    """
    CREATE TABLE models (
        bps_model_id TEXT NOT NULL,
        modeler_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        PRIMARY KEY (bps_model_id, modeler_id, role),
        FOREIGN KEY (bps_model_id) REFERENCES bps_models(bps_model_id),
        FOREIGN KEY (modeler_id) REFERENCES modelers(modeler_id)
    )
    """
)
conn.executemany(
    "INSERT INTO models (bps_model_id, modeler_id, role) VALUES (?, ?, ?)",
    models[["bps_model_id", "modeler_id", "role"]].itertuples(index=False, name=None),
)

for table, frame in dataframes.items():
    if table in {"modelers", "models", "text_df"}:
        continue
    if table == "ref_con_long":
        frame.to_sql(table, conn, if_exists="replace", index=False, dtype={"model_label": "TEXT PRIMARY KEY"})
    elif table == "ref_con_modified":
        frame.to_sql(table, conn, if_exists="replace", index=False, dtype={"Model_Code": "TEXT PRIMARY KEY"})
    else:
        frame.to_sql(table, conn, if_exists="replace", index=False)

conn.execute("PRAGMA foreign_keys = ON")
violations = conn.execute("PRAGMA foreign_key_check").fetchall()
if violations:
    raise SystemExit(f"Foreign key check failed: {violations[:10]}")
conn.commit()
conn.close()
