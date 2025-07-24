# How to Use Your Own Ecosystem Raster Data
# This script shows how to adapt the hexagonal mapping code for your specific raster

# Source the advanced hexmap functions
source("advanced_ecosystem_hexmap.R")

# === OPTION 1: Using your own raster file ===
# Replace "your_ecosystem_raster.tif" with the path to your actual raster file
your_raster_path <- "path/to/your/ecosystem_raster.tif"

# If you have a raster file, use it like this:
# map_with_your_data <- create_advanced_ecosystem_hexmap(raster_file = your_raster_path)

# === OPTION 2: Customize ecosystem types and colors ===
# If your raster has different ecosystem codes, modify this function:

get_your_ecosystem_info <- function() {
  # Update these to match YOUR ecosystem classification
  ecosystem_names <- c(
    "1" = "Douglas Fir Forest",
    "2" = "Oak Woodland", 
    "3" = "Coastal Prairie",
    "4" = "Chaparral",
    "5" = "Riparian Wetland",
    "6" = "Agricultural Land",
    "7" = "Urban Development",
    "8" = "Lakes and Rivers",
    "9" = "Alpine Meadow",
    "10" = "Desert Scrub"
    # Add more as needed for your classification system
  )
  
  # Choose colors that make sense for your ecosystems
  ecosystem_colors <- c(
    "1" = "#0d4d0d",   # Dark green for Douglas Fir
    "2" = "#8FBC8F",   # Dark sea green for Oak
    "3" = "#9ACD32",   # Yellow green for prairie
    "4" = "#CD853F",   # Peru for chaparral
    "5" = "#4682B4",   # Steel blue for wetland
    "6" = "#DAA520",   # Goldenrod for agriculture
    "7" = "#696969",   # Dim gray for urban
    "8" = "#1E90FF",   # Dodger blue for water
    "9" = "#98FB98",   # Pale green for alpine
    "10" = "#F4A460"   # Sandy brown for desert
  )
  
  return(list(names = ecosystem_names, colors = ecosystem_colors))
}

# === OPTION 3: Custom function for your specific data ===
create_your_ecosystem_map <- function(raster_file, 
                                     zoom_thresholds = c(9, 12),
                                     hex_sizes = c(0.1, 0.05, 0.025)) {
  
  # Load your raster
  cat("Loading your raster file:", raster_file, "\n")
  
  # Check if file exists
  if (!file.exists(raster_file)) {
    stop("Raster file not found: ", raster_file)
  }
  
  ecosystem_raster <- terra::rast(raster_file)
  
  # Print some info about your raster
  cat("Raster info:\n")
  cat("  Dimensions:", dim(ecosystem_raster), "\n")
  cat("  Extent:", as.vector(terra::ext(ecosystem_raster)), "\n")
  cat("  CRS:", crs(ecosystem_raster), "\n")
  cat("  Value range:", range(values(ecosystem_raster), na.rm = TRUE), "\n")
  
  # Get your custom ecosystem information
  eco_info <- get_your_ecosystem_info()
  
  # Get raster extent
  raster_extent <- terra::ext(ecosystem_raster)
  
  # Create hexagonal grids
  cat("Creating hexagonal grids...\n")
  hex_large <- create_hex_grid_advanced(raster_extent, hex_sizes[1])
  hex_medium <- create_hex_grid_advanced(raster_extent, hex_sizes[2])
  hex_small <- create_hex_grid_advanced(raster_extent, hex_sizes[3])
  
  # Aggregate data
  cat("Aggregating raster data to hexagons...\n")
  hex_data_large <- aggregate_raster_to_hexagons(ecosystem_raster, hex_large)
  hex_data_medium <- aggregate_raster_to_hexagons(ecosystem_raster, hex_medium)
  hex_data_small <- aggregate_raster_to_hexagons(ecosystem_raster, hex_small)
  
  # Add ecosystem information
  add_ecosystem_info <- function(hex_data, eco_info) {
    hex_data %>%
      mutate(
        ecosystem_name = eco_info$names[as.character(majority_ecosystem)],
        ecosystem_color = eco_info$colors[as.character(majority_ecosystem)]
      ) %>%
      # Remove hexagons with unrecognized ecosystem types
      filter(!is.na(ecosystem_name))
  }
  
  hex_data_large <- add_ecosystem_info(hex_data_large, eco_info)
  hex_data_medium <- add_ecosystem_info(hex_data_medium, eco_info)
  hex_data_small <- add_ecosystem_info(hex_data_small, eco_info)
  
  # Create map with your data
  map <- leaflet() %>%
    addProviderTiles(providers$CartoDB.Positron, group = "Light") %>%
    addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
    addProviderTiles(providers$Esri.WorldTopoMap, group = "Topographic") %>%
    
    fitBounds(
      lng1 = raster_extent[1], lat1 = raster_extent[3],
      lng2 = raster_extent[2], lat2 = raster_extent[4]
    ) %>%
    
    # Add your hexagon layers
    addPolygons(
      data = hex_data_large,
      fillColor = ~ecosystem_color,
      fillOpacity = 0.7,
      color = "white",
      weight = 0.5,
      popup = ~paste0(
        "<b>Ecosystem:</b> ", ecosystem_name, "<br>",
        "<b>Code:</b> ", majority_ecosystem, "<br>",
        "<b>Pixel Count:</b> ", pixel_count, "<br>",
        "<b>Location:</b> ", round(center_lon, 4), ", ", round(center_lat, 4)
      ),
      group = "zoom_low"
    ) %>%
    
    addPolygons(
      data = hex_data_medium,
      fillColor = ~ecosystem_color,
      fillOpacity = 0.7,
      color = "white",
      weight = 0.5,
      popup = ~paste0(
        "<b>Ecosystem:</b> ", ecosystem_name, "<br>",
        "<b>Code:</b> ", majority_ecosystem, "<br>",
        "<b>Pixel Count:</b> ", pixel_count, "<br>",
        "<b>Location:</b> ", round(center_lon, 4), ", ", round(center_lat, 4)
      ),
      group = "zoom_medium"
    ) %>%
    
    addPolygons(
      data = hex_data_small,
      fillColor = ~ecosystem_color,
      fillOpacity = 0.7,
      color = "white",
      weight = 0.5,
      popup = ~paste0(
        "<b>Ecosystem:</b> ", ecosystem_name, "<br>",
        "<b>Code:</b> ", majority_ecosystem, "<br>",
        "<b>Pixel Count:</b> ", pixel_count, "<br>",
        "<b>Location:</b> ", round(center_lon, 4), ", ", round(center_lat, 4)
      ),
      group = "zoom_high"
    ) %>%
    
    addLayersControl(
      baseGroups = c("Light", "Satellite", "Topographic"),
      options = layersControlOptions(collapsed = TRUE)
    ) %>%
    
    addLegend(
      "bottomright",
      colors = eco_info$colors,
      labels = eco_info$names,
      title = "Your Ecosystem Types",
      opacity = 0.8
    )
  
  # Add zoom-based layer switching
  map <- map %>%
    htmlwidgets::onRender(sprintf("
      function(el, x) {
        var map = this;
        var threshold1 = %d;
        var threshold2 = %d;
        
        var layers = {};
        map.eachLayer(function(layer) {
          if (layer.options && layer.options.group) {
            layers[layer.options.group] = layer;
          }
        });
        
        function updateLayers() {
          var zoom = map.getZoom();
          
          // Hide all hex layers
          ['zoom_low', 'zoom_medium', 'zoom_high'].forEach(function(group) {
            if (layers[group] && map.hasLayer(layers[group])) {
              map.removeLayer(layers[group]);
            }
          });
          
          // Show appropriate layer
          if (zoom <= threshold1) {
            if (layers['zoom_low']) map.addLayer(layers['zoom_low']);
          } else if (zoom <= threshold2) {
            if (layers['zoom_medium']) map.addLayer(layers['zoom_medium']);
          } else {
            if (layers['zoom_high']) map.addLayer(layers['zoom_high']);
          }
        }
        
        updateLayers();
        map.on('zoomend', updateLayers);
      }
    ", zoom_thresholds[1], zoom_thresholds[2]))
  
  return(map)
}

# === EXAMPLE USAGE ===

# Uncomment and modify these lines to use with your data:

# # Example 1: Basic usage with your raster
# my_map <- create_your_ecosystem_map("path/to/your/ecosystem_raster.tif")
# saveWidget(my_map, "my_ecosystem_map.html", selfcontained = TRUE)

# # Example 2: Customize zoom thresholds and hex sizes
# my_map <- create_your_ecosystem_map(
#   raster_file = "path/to/your/ecosystem_raster.tif",
#   zoom_thresholds = c(10, 13),  # Change zoom levels where hexagons switch
#   hex_sizes = c(0.15, 0.08, 0.03)  # Adjust hexagon sizes (in degrees)
# )

# === TIPS FOR YOUR DATA ===

cat("=== TIPS FOR USING YOUR OWN RASTER DATA ===\n\n")

cat("1. SUPPORTED FORMATS:\n")
cat("   - GeoTIFF (.tif, .tiff)\n")
cat("   - NetCDF (.nc)\n")
cat("   - ESRI Grid\n")
cat("   - Most GDAL-supported formats\n\n")

cat("2. RASTER REQUIREMENTS:\n")
cat("   - Should contain integer values representing ecosystem codes\n")
cat("   - Must have a defined coordinate reference system (CRS)\n")
cat("   - Values should be consistent (same code = same ecosystem)\n\n")

cat("3. CUSTOMIZATION:\n")
cat("   - Update 'get_your_ecosystem_info()' with your ecosystem names and colors\n")
cat("   - Adjust 'hex_sizes' based on your study area (smaller values = smaller hexagons)\n")
cat("   - Modify 'zoom_thresholds' to control when hexagon sizes change\n\n")

cat("4. PERFORMANCE TIPS:\n")
cat("   - For large rasters, consider resampling to lower resolution first\n")
cat("   - Start with larger hexagon sizes and fewer zoom levels\n")
cat("   - Test with a subset of your data first\n\n")

cat("5. EXAMPLE WORKFLOW:\n")
cat("   a) Load your raster: r <- terra::rast('your_file.tif')\n")
cat("   b) Check unique values: unique(values(r))\n")
cat("   c) Update ecosystem_names and ecosystem_colors accordingly\n")
cat("   d) Run create_your_ecosystem_map()\n\n")

cat("Run this script after modifying the paths and ecosystem information!\n")