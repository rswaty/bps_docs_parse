

# Load required libraries
library(stringr)
library(zip)

# Set working directory to where your .docx files are located
setwd("all_bps_docs/")

# Create output directory if it doesn't exist
if (!dir.exists("mz_zips")) {
  dir.create("mz_zips")
}

# List all .docx files
files <- list.files(pattern = "\\.docx$")

# Create a list to store map zone to files mapping
zone_to_files <- list()

# Loop through each file
for (file in files) {
  # Extract all map zones using regex
  zones <- str_extract_all(file, "_\\d+")[[1]]
  zones <- str_remove_all(zones, "_")  # Remove leading underscores
  # Add file to each zone's list
  for (zone in zones) {
    if (!zone %in% names(zone_to_files)) {
      zone_to_files[[zone]] <- c()
    }
    zone_to_files[[zone]] <- c(zone_to_files[[zone]], file)
  }
}


# Create zip files for each map zone in the "mz_zips" directory
for (zone in names(zone_to_files)) {
  zipfile_path <- file.path("mz_zips", paste0("map_zone_", zone, ".zip"))
  zip::zip(zipfile_path, files = zone_to_files[[zone]])
}

## checks ----
# Create a table of how many times each zone appears in filenames
zone_counts <- list()

for (file in files) {
  zones <- str_extract_all(file, "_\\d+")[[1]]
  zones <- str_remove_all(zones, "_")
  
  for (zone in zones) {
    if (!zone %in% names(zone_counts)) {
      zone_counts[[zone]] <- 0
    }
    zone_counts[[zone]] <- zone_counts[[zone]] + 1
  }
}

# Print zone counts
# print(zone_counts)


# Print actual file counts per zone from zone_to_files
actual_zone_file_counts <- sapply(zone_to_files, length)
# print(actual_zone_file_counts)


# Compare expected vs actual
all_zones <- union(names(zone_counts), names(zone_to_files))

for (zone in all_zones) {
  expected <- zone_counts[[zone]]
  actual <- length(zone_to_files[[zone]])
  cat("Zone:", zone, "- Expected:", expected, "- Actual:", actual, "\n")
}


for (zone in all_zones) {
  expected <- zone_counts[[zone]]
  actual <- length(zone_to_files[[zone]])
  if (expected != actual) {
    cat("Mismatch in zone", zone, ": Expected", expected, "but got", actual, "\n")
  }
}


# Create a data frame comparing expected and actual counts
zone_comparison_df <- data.frame(
  Zone = all_zones,
  Expected_Count = sapply(all_zones, function(z) zone_counts[[z]]),
  Actual_Count = sapply(all_zones, function(z) length(zone_to_files[[z]])),
  stringsAsFactors = FALSE
)

# Print the data frame
# print(zone_comparison_df)

# Optionally, save to CSV
write.csv(zone_comparison_df, "mz_zips/zone_comparison_summary.csv", row.names = FALSE)

# Create a data frame listing each file and its associated zones
file_zone_df <- data.frame(
  Zone = character(),
  File = character(),
  stringsAsFactors = FALSE
)

for (zone in names(zone_to_files)) {
  for (file in zone_to_files[[zone]]) {
    file_zone_df <- rbind(file_zone_df, data.frame(Zone = zone, File = file, stringsAsFactors = FALSE))
  }
}

# Print the data frame
# print(file_zone_df)

# Optionally, save to CSV
write.csv(file_zone_df, "mz_zips/zone_file_listing.csv", row.names = FALSE)




