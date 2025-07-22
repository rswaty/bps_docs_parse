#!/usr/bin/env python3
"""
Verification script to check if the BPS database setup is working correctly
"""

import pandas as pd
from sqlalchemy import create_engine, text
import os
import sys

def verify_connection():
    """Test database connection"""
    try:
        host = os.getenv('DB_HOST', 'localhost')
        port = os.getenv('DB_PORT', '5432') 
        database = os.getenv('DB_NAME', 'bps_database')
        user = os.getenv('DB_USER', 'postgres')
        password = os.getenv('DB_PASSWORD', 'your_password')
        
        connection_string = f"postgresql://{user}:{password}@{host}:{port}/{database}"
        engine = create_engine(connection_string)
        
        # Test connection
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            print("✓ Database connection successful")
            return engine
    except Exception as e:
        print(f"✗ Database connection failed: {e}")
        return None

def verify_tables(engine):
    """Check if all expected tables exist"""
    expected_tables = [
        'bps_indicators', 'deterministic', 'fire_frequency', 
        'modelers', 'probabilistic', 'ref_con_long', 
        'scls_descriptions', 'text_df'
    ]
    
    existing_tables = []
    
    with engine.connect() as conn:
        for table in expected_tables:
            try:
                result = conn.execute(text(f"SELECT COUNT(*) FROM {table}"))
                count = result.scalar()
                existing_tables.append(table)
                print(f"✓ Table '{table}': {count} records")
            except Exception as e:
                print(f"✗ Table '{table}': {e}")
    
    return existing_tables

def verify_joins(engine):
    """Test that tables can be joined on bps_model"""
    try:
        query = """
        SELECT i.bps_model, i.common_name, COUNT(f.bps_model) as fire_records
        FROM bps_indicators i
        LEFT JOIN fire_frequency f ON i.bps_model = f.bps_model  
        GROUP BY i.bps_model, i.common_name
        LIMIT 5
        """
        
        result = pd.read_sql(query, engine)
        print(f"✓ Table joins working: {len(result)} sample records")
        print("Sample joined data:")
        print(result.to_string(index=False))
        return True
    except Exception as e:
        print(f"✗ Table joins failed: {e}")
        return False

def main():
    print("=== BPS Database Setup Verification ===\n")
    
    # Check connection
    engine = verify_connection()
    if not engine:
        print("\nSetup incomplete: Cannot connect to database")
        sys.exit(1)
    
    print()
    
    # Check tables
    existing_tables = verify_tables(engine)
    
    print()
    
    # Test joins
    joins_ok = verify_joins(engine)
    
    print("\n=== Summary ===")
    print(f"Tables found: {len(existing_tables)}/8")
    print(f"Joins working: {'Yes' if joins_ok else 'No'}")
    
    if len(existing_tables) == 8 and joins_ok:
        print("\n🎉 Setup verification PASSED!")
        print("Your BPS database is ready to use.")
    else:
        print("\n⚠️  Setup verification FAILED!")
        print("Please check the setup and try again.")

if __name__ == "__main__":
    main()
