# BPS Database R Functions for Quarto Reports
# Functions to connect to PostgreSQL database and query BPS data

# Required libraries
library(DBI)
library(RPostgreSQL)
library(dplyr)
library(ggplot2)
library(knitr)
library(plotly)

# Database connection function
connect_bps_db <- function(host = "localhost", 
                          port = 5432, 
                          dbname = "bps_database",
                          user = "postgres", 
                          password = Sys.getenv("DB_PASSWORD")) {
  
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, 
                   host = host,
                   port = port, 
                   dbname = dbname,
                   user = user, 
                   password = password)
  return(con)
}

# Get all available BPS models
get_bps_models <- function(con) {
  query <- "SELECT DISTINCT bps_model FROM bps_indicators ORDER BY bps_model"
  dbGetQuery(con, query)
}

# Get indicators for specific BPS model(s)
get_bps_indicators <- function(con, bps_models = NULL) {
  if (is.null(bps_models)) {
    query <- "SELECT * FROM bps_indicators"
  } else {
    models_str <- paste0("'", paste(bps_models, collapse = "','"), "'")
    query <- paste0("SELECT * FROM bps_indicators WHERE bps_model IN (", models_str, ")")
  }
  dbGetQuery(con, query)
}

# Get fire frequency data
get_fire_frequency <- function(con, bps_models = NULL) {
  if (is.null(bps_models)) {
    query <- "SELECT * FROM fire_frequency"
  } else {
    models_str <- paste0("'", paste(bps_models, collapse = "','"), "'")
    query <- paste0("SELECT * FROM fire_frequency WHERE bps_model IN (", models_str, ")")
  }
  dbGetQuery(con, query)
}

# Comprehensive data for specific BPS model
get_bps_complete_data <- function(con, bps_model) {
  
  # Get all related data for the BPS model
  indicators <- dbGetQuery(con, 
    paste0("SELECT * FROM bps_indicators WHERE bps_model = '", bps_model, "'"))
  
  fire_freq <- dbGetQuery(con, 
    paste0("SELECT * FROM fire_frequency WHERE bps_model = '", bps_model, "'"))
  
  deterministic <- dbGetQuery(con, 
    paste0("SELECT * FROM deterministic WHERE bps_model = '", bps_model, "'"))
  
  probabilistic <- dbGetQuery(con, 
    paste0("SELECT * FROM probabilistic WHERE bps_model = '", bps_model, "'"))
  
  modelers <- dbGetQuery(con, 
    paste0("SELECT * FROM modelers WHERE bps_model = '", bps_model, "'"))
  
  ref_con <- dbGetQuery(con, 
    paste0("SELECT * FROM ref_con_long WHERE bps_model = '", bps_model, "'"))
  
  scls_desc <- dbGetQuery(con, 
    paste0("SELECT * FROM scls_descriptions WHERE bps_model = '", bps_model, "'"))
  
  text_data <- dbGetQuery(con, 
    paste0("SELECT * FROM text_df WHERE bps_model = '", bps_model, "'"))
  
  return(list(
    indicators = indicators,
    fire_frequency = fire_freq,
    deterministic = deterministic,
    probabilistic = probabilistic,
    modelers = modelers,
    reference_conditions = ref_con,
    state_class_descriptions = scls_desc,
    text_data = text_data
  ))
}

# Create fire frequency visualization
plot_fire_frequency <- function(con, bps_models) {
  fire_data <- get_fire_frequency(con, bps_models)
  indicators <- get_bps_indicators(con, bps_models)
  
  # Join with common names
  plot_data <- fire_data %>%
    left_join(indicators %>% select(bps_model, common_name) %>% distinct(), 
              by = "bps_model")
  
  p <- ggplot(plot_data, aes(x = severity, y = return_intervaly_years, 
                            fill = common_name)) +
    geom_col(position = "dodge") +
    facet_wrap(~common_name, scales = "free") +
    labs(title = "Fire Return Intervals by Severity",
         x = "Fire Severity", 
         y = "Return Interval (Years)",
         fill = "Species") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  return(p)
}

# Generate summary statistics
get_bps_summary <- function(con) {
  query <- "
  SELECT 
    COUNT(DISTINCT bps_model) as total_bps_models,
    COUNT(DISTINCT common_name) as total_species,
    COUNT(*) as total_indicator_records
  FROM bps_indicators"
  
  dbGetQuery(con, query)
}

# Search function for text data
search_bps_text <- function(con, search_term) {
  query <- paste0("
  SELECT bps_model, vegetation_type, geographic_range, 
         vegetation_description, disturbance_description
  FROM text_df 
  WHERE vegetation_description ILIKE '%", search_term, "%' 
     OR disturbance_description ILIKE '%", search_term, "%'
     OR geographic_range ILIKE '%", search_term, "%'")
  
  dbGetQuery(con, query)
}
