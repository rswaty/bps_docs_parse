# BPS Database System

A comprehensive database solution for Biophysical Settings (BPS) data with online hosting, R integration for Quarto reports, and user query capabilities.

## Overview

This system converts CSV files with a common `bps_model` key into a PostgreSQL database that can be:
- Hosted online (cloud platforms)
- Queried using R for Quarto reports
- Accessed by users for custom queries

## Files Structure

```
├── tables/                     # Original CSV files
├── setup_database.py          # Database setup script
├── bps_database_r_functions.R # R functions for database access
├── bps_report_template.qmd    # Quarto report template
├── docker-compose.yml         # Local PostgreSQL setup
├── requirements.txt           # Python dependencies
├── .env.example              # Environment variables template
└── README.md                 # This file
```

## Quick Start

### Option 1: Local Setup with Docker (Recommended for testing)

1. **Install Docker and Docker Compose**

2. **Start PostgreSQL database:**
   ```bash
   docker-compose up -d
   ```
   This starts:
   - PostgreSQL on port 5432
   - pgAdmin web interface on port 8080

3. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Import CSV data:**
   ```bash
   python setup_database.py
   ```

5. **Access the database:**
   - pgAdmin: http://localhost:8080 (admin@bps.com / admin)
   - Direct connection: localhost:5432

### Option 2: Cloud Hosting

#### AWS RDS Setup

1. **Create RDS PostgreSQL instance:**
   - Go to AWS RDS Console
   - Create PostgreSQL database
   - Note the endpoint, username, password

2. **Update connection settings:**
   ```bash
   cp .env.example .env
   # Edit .env with your RDS details
   ```

3. **Import data:**
   ```bash
   python setup_database.py
   ```

#### Other Cloud Providers
- **DigitalOcean**: Managed PostgreSQL databases
- **Heroku**: Heroku Postgres add-on
- **Google Cloud**: Cloud SQL for PostgreSQL

## R Integration

### Setup R Environment

```r
# Install required packages
install.packages(c("DBI", "RPostgreSQL", "dplyr", "ggplot2", "knitr", "plotly"))

# Load functions
source("bps_database_r_functions.R")

# Connect to database
con <- connect_bps_db(host = "your_host", dbname = "bps_database")
```

### Generate Quarto Reports

```bash
# Generate report for specific BPS model
quarto render bps_report_template.qmd -P bps_model:"10080_1_2_3_7"

# Generate with custom database host
quarto render bps_report_template.qmd -P bps_model:"10080_1_2_3_7" -P db_host:"your_cloud_host"
```

### Example R Usage

```r
# Get all BPS models
models <- get_bps_models(con)

# Get indicators for specific model
indicators <- get_bps_indicators(con, "10080_1_2_3_7")

# Get complete data for analysis
complete_data <- get_bps_complete_data(con, "10080_1_2_3_7")

# Create fire frequency plot
plot_fire_frequency(con, c("10080_1_2_3_7", "10090_19"))

# Search text descriptions
search_results <- search_bps_text(con, "fire")
```

## Database Schema

The database contains the following tables:

- **bps_indicators**: Species indicators (common_name, scientific_name, symbol)
- **deterministic**: Deterministic state transitions
- **fire_frequency**: Fire severity and return intervals  
- **modelers**: Model developers and reviewers
- **probabilistic**: Probabilistic state transitions
- **ref_con_long**: Reference condition data
- **scls_descriptions**: State class descriptions
- **text_df**: Detailed text descriptions and metadata

All tables are linked by the `bps_model` column with indexes for fast queries.

## User Query Examples

### SQL Queries for End Users

```sql
-- Get all species for a BPS model
SELECT * FROM bps_indicators WHERE bps_model = '10080_1_2_3_7';

-- Join multiple tables
SELECT i.common_name, f.severity, f.return_intervaly_years 
FROM bps_indicators i
JOIN fire_frequency f ON i.bps_model = f.bps_model
WHERE i.bps_model = '10080_1_2_3_7';

-- Search by species
SELECT DISTINCT bps_model, common_name 
FROM bps_indicators 
WHERE common_name ILIKE '%oak%';

-- Get models with fire data
SELECT DISTINCT i.bps_model, i.common_name
FROM bps_indicators i
WHERE EXISTS (SELECT 1 FROM fire_frequency f WHERE f.bps_model = i.bps_model);
```

### Tools for Users

1. **pgAdmin**: Web-based interface (included in Docker setup)
2. **DBeaver**: Free database tool with PostgreSQL support
3. **R/RStudio**: Using the provided R functions
4. **Python**: Using pandas and SQLAlchemy
5. **Any SQL client**: Standard PostgreSQL connection

## Security & Access Control

For production deployment:

1. **Change default passwords**
2. **Use environment variables for credentials**
3. **Set up SSL connections**
4. **Configure firewall rules**
5. **Create read-only users for end users**

Example read-only user creation:
```sql
CREATE USER readonly_user WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE bps_database TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
```

## Backup & Maintenance

```bash
# Backup database
pg_dump -h localhost -U postgres bps_database > bps_backup.sql

# Restore database
psql -h localhost -U postgres bps_database < bps_backup.sql
```

## Troubleshooting

### Common Issues

1. **Connection refused**: Check if PostgreSQL is running
2. **Authentication failed**: Verify username/password
3. **CSV import errors**: Check file paths and formats
4. **R connection issues**: Install RPostgreSQL package

### Support

- Check PostgreSQL logs for database issues
- Verify CSV file integrity
- Test connections with `psql` command line tool

## Contributing

To add new CSV files:
1. Ensure they have a `bps_model` column
2. Add to the `csv_files` dictionary in `setup_database.py`
3. Run the setup script to import new data

---

*For questions about the BPS data model or scientific interpretation, consult the original data documentation.*
