# Install Required Packages for Ecosystem Hexagonal Mapping
# Run this script first to install all necessary R packages

cat("Installing required packages for ecosystem hexagonal mapping...\n\n")

# List of required packages
required_packages <- c(
  "leaflet",       # Interactive maps
  "sf",           # Spatial features
  "terra",        # Raster data handling
  "dplyr",        # Data manipulation
  "htmlwidgets",  # Save HTML widgets
  "RColorBrewer", # Color palettes
  "viridis"       # Color palettes
)

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  
  if(length(new_packages) > 0) {
    cat("Installing new packages:", paste(new_packages, collapse = ", "), "\n")
    install.packages(new_packages, dependencies = TRUE)
  } else {
    cat("All required packages are already installed.\n")
  }
}

# Install missing packages
install_if_missing(required_packages)

# Load packages to test installation
cat("\nTesting package installation...\n")
success <- TRUE

for(pkg in required_packages) {
  tryCatch({
    library(pkg, character.only = TRUE)
    cat("✓", pkg, "loaded successfully\n")
  }, error = function(e) {
    cat("✗", pkg, "failed to load:", e$message, "\n")
    success <<- FALSE
  })
}

if(success) {
  cat("\n🎉 All packages installed and loaded successfully!\n")
  cat("You can now run the ecosystem hexagonal mapping scripts.\n\n")
  
  cat("Next steps:\n")
  cat("1. Run 'ecosystem_hexmap.R' for basic functionality\n")
  cat("2. Run 'advanced_ecosystem_hexmap.R' for enhanced features\n")
  cat("3. Modify 'use_your_own_raster.R' to use your own data\n")
} else {
  cat("\n❌ Some packages failed to install/load.\n")
  cat("Please check the error messages above and try installing manually.\n")
}

# Print system information for troubleshooting
cat("\nSystem Information:\n")
cat("R version:", R.version.string, "\n")
cat("Platform:", R.version$platform, "\n")
cat("Working directory:", getwd(), "\n")

# Check if GDAL is available (important for spatial operations)
tryCatch({
  sf::sf_extSoftVersion()
  cat("✓ GDAL and spatial libraries are available\n")
}, error = function(e) {
  cat("⚠ Warning: GDAL or spatial libraries may not be properly configured\n")
  cat("  This could cause issues with raster processing\n")
})