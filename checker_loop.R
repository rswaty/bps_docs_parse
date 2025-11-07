

library(tidyverse)

# Read reference condition table once
refcon <- read_csv("ReferenceConditionTable14August2020.csv") %>%
  select(Model_Code)

# Create a temporary folder for unzipped files
dir.create("unzipped_temp", showWarnings = FALSE)

# Create lists to store results
missing_files_list <- list()
suspicious_files_all <- tibble()

# Loop through zones 1 to 79
for (zone in 1:79) {
  
  zone_str <- as.character(zone)
  
  # Build zone-specific strings
  zone_string1 <- paste0("_", zone_str, "$")
  zone_string2 <- paste0("_", zone_str, "_")
  
  # Filter model codes for the current zone
  zone_check <- refcon %>%
    mutate(inzone = case_when(
      str_detect(Model_Code, zone_string1) ~ "yes",
      str_detect(Model_Code, zone_string2) ~ "yes",
      .default = "no")
    ) %>%
    filter(inzone == "yes")
  
  # Build path to zip file
  zip_path <- paste0("all_bps_docs/mz_zips/map_zone_", zone_str, ".zip")
  
  # Define extraction folder
  unzip_folder <- paste0("unzipped_temp/map_zone_", zone_str)
  dir.create(unzip_folder, showWarnings = FALSE)
  
  # Unzip the file
  if (file.exists(zip_path)) {
    unzip(zip_path, exdir = unzip_folder)
  } else {
    cat("Zone", zone_str, "- zip file not found.\n")
    next
  }
  
  # Get raw file names
  raw_files <- list.files(unzip_folder)
  
  # Clean filenames for comparison
  files <- tibble(
    raw_file_name = raw_files,
    file_name = str_remove(raw_files, "\\.[^.]+$") %>%
      str_trim()
  )
  
  # Identify suspicious filenames
  suspicious_files <- files %>%
    filter(
      str_detect(raw_file_name, "^\\s|\\s$") |         # leading/trailing space
        str_detect(raw_file_name, "\\s{1,}") |           # internal spaces
        str_detect(raw_file_name, "__") |                # double underscores
        str_detect(raw_file_name, "[^\\w\\d_\\.-]")      # odd characters
    ) %>%
    mutate(zone = zone_str)
  
  # Append suspicious filenames
  if (nrow(suspicious_files) > 0) {
    suspicious_files_all <- bind_rows(suspicious_files_all, suspicious_files)
  }
  
  # Compare cleaned filenames to refcon model codes
  zone_check_names <- zone_check %>%
    mutate(infiles = if_else(
      Model_Code %in% files$file_name, "yes", "no")) %>%
    filter(infiles == "no") %>%
    mutate(zone = zone_str) %>%
    select(zone, missing_model_code = Model_Code)
  
  # Store missing files
  if (nrow(zone_check_names) > 0) {
    missing_files_list[[zone_str]] <- zone_check_names
    cat("Zone", zone_str, "- missing files:", nrow(zone_check_names), "\n")
  }
}

# Combine all missing entries into one data frame
missing_files_df <- bind_rows(missing_files_list)

# Write results to CSV
if (nrow(missing_files_df) > 0) {
  write_csv(missing_files_df, "missing_model_codes_by_zone.csv")
  cat("Missing model codes written to missing_model_codes_by_zone.csv\n")
} else {
  cat("No missing model codes found.\n")
}

if (nrow(suspicious_files_all) > 0) {
  write_csv(suspicious_files_all, "suspicious_filenames_by_zone.csv")
  cat("Suspicious filenames written to suspicious_filenames_by_zone.csv\n")
} else {
  cat("No suspicious filenames found.\n")
}
