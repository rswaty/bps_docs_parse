#!/usr/bin/env python3
"""
Simple command-line query interface for BPS database
Allows users to run predefined queries or custom SQL
"""

import pandas as pd
from sqlalchemy import create_engine
import sys
import os

def get_connection():
    """Get database connection"""
    host = os.getenv('DB_HOST', 'localhost')
    port = os.getenv('DB_PORT', '5432')
    database = os.getenv('DB_NAME', 'bps_database')
    user = os.getenv('DB_USER', 'postgres')
    password = os.getenv('DB_PASSWORD', 'your_password')
    
    connection_string = f"postgresql://{user}:{password}@{host}:{port}/{database}"
    return create_engine(connection_string)

def predefined_queries():
    """Return dictionary of predefined queries"""
    return {
        "1": {
            "name": "List all BPS models",
            "query": "SELECT DISTINCT bps_model FROM bps_indicators ORDER BY bps_model"
        },
        "2": {
            "name": "Count records by table",
            "query": """
            SELECT 'bps_indicators' as table_name, COUNT(*) as record_count FROM bps_indicators
            UNION ALL
            SELECT 'fire_frequency', COUNT(*) FROM fire_frequency
            UNION ALL  
            SELECT 'deterministic', COUNT(*) FROM deterministic
            UNION ALL
            SELECT 'probabilistic', COUNT(*) FROM probabilistic
            UNION ALL
            SELECT 'modelers', COUNT(*) FROM modelers
            UNION ALL
            SELECT 'ref_con_long', COUNT(*) FROM ref_con_long
            UNION ALL
            SELECT 'scls_descriptions', COUNT(*) FROM scls_descriptions
            UNION ALL
            SELECT 'text_df', COUNT(*) FROM text_df
            """
        },
        "3": {
            "name": "Species by common name search",
            "query": "SELECT DISTINCT bps_model, common_name, scientific_name FROM bps_indicators WHERE common_name ILIKE '%{}%' ORDER BY common_name",
            "requires_input": True,
            "input_prompt": "Enter species common name to search for: "
        },
        "4": {
            "name": "Fire frequency for BPS model",
            "query": "SELECT * FROM fire_frequency WHERE bps_model = '{}' ORDER BY severity",
            "requires_input": True,
            "input_prompt": "Enter BPS model (e.g., 10080_1_2_3_7): "
        },
        "5": {
            "name": "Complete data for BPS model",
            "query": """
            SELECT 'Indicators' as data_type, COUNT(*) as count FROM bps_indicators WHERE bps_model = '{}'
            UNION ALL
            SELECT 'Fire Frequency', COUNT(*) FROM fire_frequency WHERE bps_model = '{}'
            UNION ALL
            SELECT 'Deterministic', COUNT(*) FROM deterministic WHERE bps_model = '{}'
            UNION ALL
            SELECT 'Probabilistic', COUNT(*) FROM probabilistic WHERE bps_model = '{}'
            """,
            "requires_input": True,
            "input_prompt": "Enter BPS model: "
        }
    }

def main():
    print("=== BPS Database Query Interface ===\n")
    
    try:
        engine = get_connection()
        print("✓ Connected to database\n")
    except Exception as e:
        print(f"✗ Failed to connect to database: {e}")
        print("Check your database connection settings")
        sys.exit(1)
    
    queries = predefined_queries()
    
    while True:
        print("Available queries:")
        for key, query_info in queries.items():
            print(f"  {key}. {query_info['name']}")
        print("  c. Custom SQL query")
        print("  q. Quit")
        
        choice = input("\nSelect an option: ").strip().lower()
        
        if choice == 'q':
            break
        elif choice == 'c':
            sql = input("Enter your SQL query: ")
            try:
                result = pd.read_sql(sql, engine)
                print(f"\nResults ({len(result)} rows):")
                print(result.to_string(index=False))
            except Exception as e:
                print(f"Error executing query: {e}")
        elif choice in queries:
            query_info = queries[choice]
            query = query_info['query']
            
            if query_info.get('requires_input'):
                user_input = input(query_info['input_prompt'])
                if choice == '5':  # Special case for query 5 (multiple placeholders)
                    query = query.format(user_input, user_input, user_input, user_input)
                else:
                    query = query.format(user_input)
            
            try:
                result = pd.read_sql(query, engine)
                print(f"\nResults ({len(result)} rows):")
                print(result.to_string(index=False))
            except Exception as e:
                print(f"Error executing query: {e}")
        else:
            print("Invalid option")
        
        print("\n" + "-"*50 + "\n")
    
    print("Goodbye!")

if __name__ == "__main__":
    main()
