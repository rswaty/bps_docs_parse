# Advanced Ecosystem Hexagonal Map with Automatic Zoom-Based Layer Switching
# This version provides smoother transitions and better performance

library(leaflet)
library(sf)
library(terra)
library(dplyr)
library(htmlwidgets)
library(RColorBrewer)

# Enhanced function to create hexagonal grid with proper CRS handling
create_hex_grid_advanced <- function(extent_obj, cell_size, target_crs = 4326) {
  # Convert extent to sf polygon
  bbox_poly <- st_bbox(c(xmin = extent_obj[1], ymin = extent_obj[3], 
                        xmax = extent_obj[2], ymax = extent_obj[4]),
                      crs = st_crs(target_crs)) %>%
    st_as_sfc()
  
  # Create hexagonal grid
  hex_grid <- st_make_grid(
    bbox_poly, 
    cellsize = cell_size, 
    square = FALSE,
    what = "polygons"
  ) %>%
    st_sf(hex_id = 1:length(.)) %>%
    st_set_crs(target_crs)
  
  # Add centroid coordinates for better labeling
  centroids <- st_centroid(hex_grid)
  coords <- st_coordinates(centroids)
  hex_grid$center_lon <- coords[,1]
  hex_grid$center_lat <- coords[,2]
  
  return(hex_grid)
}

# Optimized function to aggregate raster data to hexagons
aggregate_raster_to_hexagons <- function(raster_data, hex_grid, value_column = NULL) {
  
  # Ensure both have the same CRS
  raster_crs <- crs(raster_data)
  hex_crs <- st_crs(hex_grid)$wkt
  
  if (!is.null(raster_crs) && raster_crs != hex_crs) {
    # Transform hexagons to raster CRS for extraction
    hex_grid_proj <- st_transform(hex_grid, raster_crs)
  } else {
    hex_grid_proj <- hex_grid
  }
  
  # Extract raster values for each hexagon using terra::extract
  extracted_values <- terra::extract(raster_data, vect(hex_grid_proj), fun = "modal", na.rm = TRUE)
  
  # Handle the case where terra::extract returns a data frame
  if (is.data.frame(extracted_values)) {
    if (ncol(extracted_values) > 2) {
      # Multiple columns - use the first non-ID column
      value_col <- names(extracted_values)[2]
    } else {
      value_col <- names(extracted_values)[2]
    }
    extracted_values$majority_ecosystem <- extracted_values[[value_col]]
  } else {
    # Single column of values
    extracted_values <- data.frame(
      ID = 1:nrow(hex_grid_proj),
      majority_ecosystem = extracted_values
    )
  }
  
  # Count pixels per hexagon for additional information
  pixel_counts <- terra::extract(raster_data, vect(hex_grid_proj), fun = "length", na.rm = TRUE)
  if (is.data.frame(pixel_counts)) {
    extracted_values$pixel_count <- pixel_counts[[2]]
  } else {
    extracted_values$pixel_count <- pixel_counts
  }
  
  # Merge back with hexagon geometries
  hex_grid$hex_id <- 1:nrow(hex_grid)
  result <- hex_grid %>%
    mutate(
      majority_ecosystem = extracted_values$majority_ecosystem,
      pixel_count = extracted_values$pixel_count
    ) %>%
    filter(!is.na(majority_ecosystem))
  
  return(result)
}

# Function to create a more diverse sample ecosystem raster
create_sample_ecosystem_raster_advanced <- function() {
  # Define extent (California coast example)
  ext <- c(-122, -117, 34, 39)
  
  # Create base raster
  r <- terra::rast(extent = ext, resolution = 0.005, crs = "EPSG:4326")
  
  # Create more realistic ecosystem patterns
  set.seed(42)
  
  # Create elevation-like gradient
  rows <- nrow(r)
  cols <- ncol(r)
  
  # Initialize with base values
  values_matrix <- matrix(nrow = rows, ncol = cols)
  
  for (i in 1:rows) {
    for (j in 1:cols) {
      # Distance from coast effect (western edge)
      coast_distance <- j / cols
      
      # Elevation effect (random but spatially correlated)
      elevation_effect <- sin(i/rows * pi) * cos(j/cols * pi * 2)
      
      # Combine effects to determine ecosystem
      combined_effect <- coast_distance + elevation_effect * 0.3
      
      if (combined_effect < 0.2) {
        ecosystem <- sample(c(5, 8), 1, prob = c(0.7, 0.3))  # Wetland or Water
      } else if (combined_effect < 0.4) {
        ecosystem <- sample(c(1, 2), 1, prob = c(0.6, 0.4))  # Forest types
      } else if (combined_effect < 0.6) {
        ecosystem <- sample(c(3, 4), 1, prob = c(0.5, 0.5))  # Grassland or Shrubland
      } else if (combined_effect < 0.8) {
        ecosystem <- sample(c(4, 6), 1, prob = c(0.6, 0.4))  # Shrubland or Agricultural
      } else {
        ecosystem <- sample(c(6, 7), 1, prob = c(0.7, 0.3))  # Agricultural or Urban
      }
      
      values_matrix[i, j] <- ecosystem
    }
  }
  
  # Set values and name
  values(r) <- as.vector(values_matrix)
  names(r) <- "ecosystem_type"
  
  return(r)
}

# Enhanced ecosystem information with better color scheme
get_ecosystem_info_advanced <- function() {
  ecosystem_names <- c(
    "1" = "Coniferous Forest",
    "2" = "Mixed/Deciduous Forest", 
    "3" = "Grassland/Prairie",
    "4" = "Shrubland/Chaparral",
    "5" = "Wetland/Marsh",
    "6" = "Agricultural/Cropland",
    "7" = "Urban/Developed",
    "8" = "Water Bodies"
  )
  
  ecosystem_colors <- c(
    "1" = "#0f4c0f", # Dark forest green
    "2" = "#228B22", # Forest green
    "3" = "#9ACD32", # Yellow green
    "4" = "#CD853F", # Peru brown
    "5" = "#4682B4", # Steel blue
    "6" = "#DAA520", # Goldenrod
    "7" = "#808080", # Gray
    "8" = "#1E90FF"  # Dodger blue
  )
  
  return(list(names = ecosystem_names, colors = ecosystem_colors))
}

# Main function with enhanced features
create_advanced_ecosystem_hexmap <- function(raster_file = NULL, 
                                           zoom_thresholds = c(8, 11),
                                           hex_sizes = c(0.08, 0.04, 0.02)) {
  
  # Load or create raster data
  if (is.null(raster_file)) {
    cat("Creating sample ecosystem data...\n")
    ecosystem_raster <- create_sample_ecosystem_raster_advanced()
  } else {
    cat("Loading raster file:", raster_file, "\n")
    ecosystem_raster <- terra::rast(raster_file)
  }
  
  # Get ecosystem information
  eco_info <- get_ecosystem_info_advanced()
  
  # Get raster extent
  raster_extent <- terra::ext(ecosystem_raster)
  
  # Create hexagonal grids at different resolutions
  cat("Creating hexagonal grids at multiple resolutions...\n")
  hex_large <- create_hex_grid_advanced(raster_extent, hex_sizes[1])
  hex_medium <- create_hex_grid_advanced(raster_extent, hex_sizes[2])
  hex_small <- create_hex_grid_advanced(raster_extent, hex_sizes[3])
  
  # Aggregate ecosystem data to hexagons
  cat("Aggregating raster data to hexagons...\n")
  hex_data_large <- aggregate_raster_to_hexagons(ecosystem_raster, hex_large)
  hex_data_medium <- aggregate_raster_to_hexagons(ecosystem_raster, hex_medium)
  hex_data_small <- aggregate_raster_to_hexagons(ecosystem_raster, hex_small)
  
  # Add ecosystem names and colors to each dataset
  add_ecosystem_info <- function(hex_data, eco_info) {
    hex_data %>%
      mutate(
        ecosystem_name = eco_info$names[as.character(majority_ecosystem)],
        ecosystem_color = eco_info$colors[as.character(majority_ecosystem)]
      )
  }
  
  hex_data_large <- add_ecosystem_info(hex_data_large, eco_info)
  hex_data_medium <- add_ecosystem_info(hex_data_medium, eco_info)
  hex_data_small <- add_ecosystem_info(hex_data_small, eco_info)
  
  # Create the interactive map
  cat("Building interactive Leaflet map...\n")
  map <- leaflet() %>%
    # Add multiple base layers
    addProviderTiles(providers$CartoDB.Positron, group = "Light Theme") %>%
    addProviderTiles(providers$OpenStreetMap, group = "Street Map") %>%
    addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
    addProviderTiles(providers$Esri.WorldTopoMap, group = "Topographic") %>%
    
    # Set initial view
    fitBounds(
      lng1 = raster_extent[1], lat1 = raster_extent[3],
      lng2 = raster_extent[2], lat2 = raster_extent[4]
    ) %>%
    
    # Add legend
    addLegend(
      "bottomright",
      colors = eco_info$colors,
      labels = eco_info$names,
      title = "Ecosystem Types",
      opacity = 0.8
    )
  
  # Add hexagon layers (initially hidden)
  add_hex_layer <- function(map, hex_data, group_name, opacity = 0.7) {
    map %>%
      addPolygons(
        data = hex_data,
        fillColor = ~ecosystem_color,
        fillOpacity = opacity,
        color = "white",
        weight = 0.8,
        popup = ~paste0(
          "<b>Ecosystem:</b> ", ecosystem_name, "<br>",
          "<b>Pixel Count:</b> ", pixel_count, "<br>",
          "<b>Coordinates:</b> ", round(center_lon, 3), ", ", round(center_lat, 3)
        ),
        group = group_name
      )
  }
  
  map <- map %>%
    add_hex_layer(hex_data_large, "zoom_1_8") %>%
    add_hex_layer(hex_data_medium, "zoom_9_11") %>%
    add_hex_layer(hex_data_small, "zoom_12_plus") %>%
    
    # Add layer control for base maps only
    addLayersControl(
      baseGroups = c("Light Theme", "Street Map", "Satellite", "Topographic"),
      options = layersControlOptions(collapsed = TRUE)
    )
  
  # Enhanced JavaScript for smooth zoom-based layer switching
  map <- map %>%
    htmlwidgets::onRender(sprintf("
      function(el, x) {
        var map = this;
        var zoomThreshold1 = %d;
        var zoomThreshold2 = %d;
        
        // Get layer groups
        var layers = {
          large: null,
          medium: null,
          small: null
        };
        
        // Find layer groups by iterating through map layers
        map.eachLayer(function(layer) {
          if (layer.options && layer.options.group) {
            if (layer.options.group === 'zoom_1_8') {
              layers.large = layer;
            } else if (layer.options.group === 'zoom_9_11') {
              layers.medium = layer;
            } else if (layer.options.group === 'zoom_12_plus') {
              layers.small = layer;
            }
          }
        });
        
        // Function to update layer visibility based on zoom
        function updateLayerVisibility() {
          var currentZoom = map.getZoom();
          
          // Remove all hex layers first
          if (layers.large && map.hasLayer(layers.large)) {
            map.removeLayer(layers.large);
          }
          if (layers.medium && map.hasLayer(layers.medium)) {
            map.removeLayer(layers.medium);
          }
          if (layers.small && map.hasLayer(layers.small)) {
            map.removeLayer(layers.small);
          }
          
          // Add appropriate layer based on zoom level
          if (currentZoom <= zoomThreshold1) {
            if (layers.large) map.addLayer(layers.large);
          } else if (currentZoom <= zoomThreshold2) {
            if (layers.medium) map.addLayer(layers.medium);
          } else {
            if (layers.small) map.addLayer(layers.small);
          }
        }
        
        // Initial setup
        updateLayerVisibility();
        
        // Listen for zoom changes
        map.on('zoomend', updateLayerVisibility);
        
        // Add zoom level indicator
        var zoomIndicator = L.control({position: 'topleft'});
        zoomIndicator.onAdd = function(map) {
          var div = L.DomUtil.create('div', 'zoom-indicator');
          div.style.background = 'rgba(255,255,255,0.8)';
          div.style.padding = '5px';
          div.style.border = '1px solid #ccc';
          div.style.borderRadius = '3px';
          div.innerHTML = 'Zoom: ' + map.getZoom();
          return div;
        };
        zoomIndicator.addTo(map);
        
        // Update zoom indicator
        map.on('zoomend', function() {
          var indicator = document.querySelector('.zoom-indicator');
          if (indicator) {
            indicator.innerHTML = 'Zoom: ' + map.getZoom();
          }
        });
      }
    ", zoom_thresholds[1], zoom_thresholds[2]))
  
  return(map)
}

# Create and display the map
cat("=== Advanced Ecosystem Hexagonal Map ===\n")
map <- create_advanced_ecosystem_hexmap()

# Display in R
print(map)

# Save to HTML file
cat("Saving map to 'advanced_ecosystem_hexmap.html'...\n")
saveWidget(map, "advanced_ecosystem_hexmap.html", selfcontained = TRUE)

cat("Interactive map created successfully!\n")
cat("Features:\n")
cat("- Automatic hexagon size adjustment based on zoom level\n")
cat("- Multiple base map options\n")
cat("- Zoom level indicator\n")
cat("- Detailed popups with ecosystem information\n")
cat("- Optimized performance with proper layer management\n")
cat("\nOpen 'advanced_ecosystem_hexmap.html' in your browser to explore!\n")