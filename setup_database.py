#!/usr/bin/env python3
"""
Database setup script for BPS (Biophysical Settings) data
Creates PostgreSQL database and imports CSV files with bps_model as common key
"""

import pandas as pd
import psycopg2
from sqlalchemy import create_engine, text
import os
import sys
from pathlib import Path

def create_database_connection(host='localhost', port=5432, database='bps_database', 
                             user='postgres', password='your_password'):
    """Create database connection string"""
    return f"postgresql://{user}:{password}@{host}:{port}/{database}"

def setup_database(connection_string):
    """Set up the database and import CSV files"""
    
    # Create SQLAlchemy engine
    engine = create_engine(connection_string)
    
    # Dictionary mapping CSV files to table names
    csv_files = {
        'bps_indicators': 'tables/bps_indicators.csv',
        'deterministic': 'tables/deterministic.csv', 
        'fire_frequency': 'tables/fire_frequency.csv',
        'modelers': 'tables/modelers.csv',
        'probabilistic': 'tables/probabilistic.csv',
        'ref_con_long': 'tables/ref_con_long.csv',
        'scls_descriptions': 'tables/scls_descriptions.csv',
        'text_df': 'tables/text_df.csv'
    }
    
    print("Starting database setup...")
    
    # Import each CSV file
    for table_name, csv_path in csv_files.items():
        if not os.path.exists(csv_path):
            print(f"Warning: {csv_path} not found, skipping...")
            continue
            
        print(f"Importing {csv_path} to table {table_name}...")
        
        try:
            # Read CSV file
            df = pd.read_csv(csv_path)
            
            # Clean column names (remove spaces, special characters)
            df.columns = df.columns.str.replace(' ', '_').str.replace('(', '').str.replace(')', '').str.replace('-', '_')
            
            # Import to PostgreSQL
            df.to_sql(table_name, engine, if_exists='replace', index=False)
            
            print(f"✓ Successfully imported {len(df)} rows to {table_name}")
            
        except Exception as e:
            print(f"✗ Error importing {csv_path}: {e}")
    
    # Create indexes on bps_model for better query performance
    with engine.connect() as conn:
        for table_name in csv_files.keys():
            try:
                conn.execute(text(f"CREATE INDEX IF NOT EXISTS idx_{table_name}_bps_model ON {table_name} (bps_model)"))
                print(f"✓ Created index on {table_name}.bps_model")
            except Exception as e:
                print(f"Warning: Could not create index on {table_name}: {e}")
        conn.commit()
    
    print("\n=== Database Setup Complete! ===")

if __name__ == "__main__":
    connection_string = create_database_connection()
    setup_database(connection_string)
