import sqlite3
import pandas as pd

# Script Configs
DB_NAME = 'bps_database.db'
TABLES = [
    'bps_indicators',
    'deterministic',
    'fire_frequency',
    'modelers',
    'probabilistic',
    'ref_con_long',
    'ref_con_modified',
    'scls_descriptions',
    'text_df',
]

pd.options.mode.copy_on_write = True

# Load CSV files to pandas dataframes and strip whitespace from column names
dataframes = {}
for table in TABLES:
    dataframes[table] = pd.read_csv(f'tables/{table}.csv')
    dataframes[table].columns = dataframes[table].columns.str.strip()
    dataframes[table] = dataframes[table].dropna(axis=1, how='all')

# ---------------------- CREATE NEW TABLES FOR MODELERS AND MODELS -----------------------------
# clean up modelers table
dataframes['modelers'] = dataframes['modelers'].drop(columns=['Unnamed: 9'])
dataframes['modelers']['modeler_email'] = dataframes['modelers']['modeler_email'].str.lower()
dataframes['modelers']['modelers'] = dataframes['modelers']['modelers'].str.lower()
dataframes['modelers']['reviewers'] = dataframes['modelers']['reviewers'].str.lower()
dataframes['modelers']['reviewer_email'] = dataframes['modelers']['reviewer_email'].str.lower()
dataframes['modelers'] = dataframes['modelers'].dropna(subset=['modelers', 'modeler_email', 'reviewers', 'reviewer_email'], how='all') # drop rows with all nulls
print(len(dataframes['modelers']))

num_unique_bps_models = len(dataframes['modelers']['bps_model_id'].unique())
print(f"Number of unique BPS models: {num_unique_bps_models}")

# split modelers table to two tables
# First table: Models, to have modeler_id and bps_model_id, and attributes: reviewers and reviewer_email,
# modeler_email and modelers are needed to link to modelers table for now, but will be dropped later
models = dataframes['modelers'][['modeler_email', 'modelers', 'bps_model_id', 'reviewers', 'reviewer_email']]

# "Modelers": new primary key modeler_id, name, and email,
modelers = dataframes['modelers'][['modelers', 'modeler_email']]


# create three tables for merge, one for modelers with no emails, one for modelers with emails, and one for modelers with no info
modelers_without_emails = modelers[modelers['modeler_email'].isna()]
modelers_without_emails.dropna(subset=['modelers'], inplace=True)
modelers_without_emails.drop_duplicates(inplace=True, subset=['modelers'])
modelers_without_emails.reset_index(drop=True, inplace=True)
modelers_without_emails['modeler_id'] = modelers_without_emails.index

# need reviewer info to merge merge back with models table
modelers_with_no_info = models[models['modelers'].isna() & models['modeler_email'].isna()]
modelers_with_no_info.dropna(subset=['reviewers', 'reviewer_email'], inplace=True) # redundant, but just in case
modelers_with_no_info.reset_index(drop=True, inplace=True)
modelers_with_no_info['modeler_id'] = modelers_with_no_info.index + len(modelers_without_emails)

# we have modelers who have entered their names differently but have the same email
# want to get rid of these duplicates
modelers_with_emails = modelers[modelers['modeler_email'].notna()]
modelers_with_emails.drop_duplicates(inplace=True, subset=['modeler_email'])
modelers_with_emails.reset_index(drop=True, inplace=True)
modelers_with_emails['modeler_id'] = modelers_with_emails.index+len(modelers_without_emails)+len(modelers_with_no_info)

modelers = pd.concat([modelers_without_emails, modelers_with_emails, modelers_with_no_info]).reset_index(drop=True)
modelers.drop(columns=['reviewers', 'reviewer_email', 'bps_model_id'], inplace=True)

# merge the three tables
modelers_with_emails.drop(columns=['modelers'], inplace=True) # drop modelers column, we don't need it

merged_by_email = models.merge(modelers_with_emails, on=['modeler_email'], how='inner')
merged_by_name = models.merge(modelers_without_emails, on=['modelers', 'modeler_email'], how='inner')
models = pd.concat([merged_by_email, merged_by_name, modelers_with_no_info])
models.drop(columns=['modeler_email', 'modelers'], inplace=True)

models.sort_values(by=['bps_model_id', 'modeler_id'], inplace=True)
models.reset_index(drop=True, inplace=True)

# write to tables
dataframes['models'] = models
dataframes['modelers'] = modelers

print(models)
print(modelers.sort_values(by='modeler_id'))
print(dataframes['modelers'])
assert (num_unique_bps_models == len(models['bps_model_id'].unique())), "Number of unique BPS models does not match"

# ---------------------- CREATE DATABASE! -----------------------------
# Connect to SQLite database
conn = sqlite3.connect(DB_NAME)

# create main bps_models table FIRST (referenced by foreign key)
dataframes['text_df'] = pd.read_csv('tables/text_df.csv')
dataframes['text_df'].to_sql("bps_models", conn, if_exists='replace', index=False, dtype={'bps_model_id': 'TEXT PRIMARY KEY'})

# Create modelers table SECOND (referenced by foreign key)
dataframes['modelers'].to_sql("modelers", conn, if_exists='replace', index=False, dtype={'modeler_id': 'INTEGER PRIMARY KEY'})

# Create models table with composite primary key and foreign keys THIRD
conn.execute('DROP TABLE IF EXISTS models')  # Drop if exists to recreate
conn.execute('''
    CREATE TABLE models (
        bps_model_id TEXT NOT NULL,
        modeler_id INTEGER NOT NULL,
        reviewers TEXT,
        reviewer_email TEXT,
        PRIMARY KEY (bps_model_id, modeler_id),
        FOREIGN KEY (bps_model_id) REFERENCES bps_models(bps_model_id),
        FOREIGN KEY (modeler_id) REFERENCES modelers(modeler_id)
    )
''')

# Insert data into models table using executemany for better performance
models_data = models[['bps_model_id', 'modeler_id', 'reviewers', 'reviewer_email']].values.tolist()
conn.executemany('''
    INSERT INTO models (bps_model_id, modeler_id, reviewers, reviewer_email)
    VALUES (?, ?, ?, ?)
''', models_data)

# Load dataframes to SQLite database
for table in dataframes.keys():
    # current index is created by pandas, so we need to remove it
    # also need to set the primary key to bps_model_label, as it is the only column that is unique
    # then need to set the foreign key to bps_model
    if table == 'ref_con_long':
        dataframes[table].to_sql(table, conn, if_exists='replace', index=False, dtype={'model_label': 'TEXT PRIMARY KEY'})
    elif table == 'ref_con_modified':
        dataframes[table].to_sql(table, conn, if_exists='replace', index=False, dtype={'bps_model_id': 'TEXT PRIMARY KEY'})
    elif table in ['modelers', 'models', 'text_df']:
        # Skip these - already created above
        continue
    else:
        # also need to set the primary key to the first column
        dataframes[table].to_sql(table, conn, if_exists='replace', index=False)

# Close connection
conn.close()
