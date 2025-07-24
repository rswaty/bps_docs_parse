# Ecosystem Hexagonal Map with Leaflet
# Interactive map that displays majority ecosystem per hexagon
# Hexagon size changes with zoom level

# Load required libraries
library(leaflet)
library(sf)
library(terra)
library(dplyr)
library(htmlwidgets)
library(RColorBrewer)
library(viridis)

# Function to create hexagonal grid at different resolutions
create_hex_grid <- function(bbox, cell_size) {
  # Create hexagonal grid using sf
  hex_grid <- st_make_grid(
    bbox, 
    cellsize = cell_size, 
    square = FALSE
  ) %>%
    st_sf(hex_id = 1:length(.)) %>%
    st_set_crs(st_crs(bbox))
  
  return(hex_grid)
}

# Function to aggregate raster data to hexagons
aggregate_to_hexagons <- function(raster_data, hex_grid) {
  # Extract raster values to points
  raster_points <- terra::as.points(raster_data, values = TRUE, na.rm = TRUE)
  raster_sf <- st_as_sf(raster_points)
  
  # Set CRS if needed
  if (is.na(st_crs(raster_sf))) {
    st_crs(raster_sf) <- st_crs(hex_grid)
  }
  
  # Transform to same CRS if different
  if (st_crs(raster_sf) != st_crs(hex_grid)) {
    raster_sf <- st_transform(raster_sf, st_crs(hex_grid))
  }
  
  # Spatial join and find majority ecosystem per hexagon
  joined <- st_join(hex_grid, raster_sf)
  
  # Calculate majority ecosystem per hexagon
  hex_summary <- joined %>%
    st_drop_geometry() %>%
    group_by(hex_id) %>%
    summarise(
      majority_ecosystem = names(sort(table(!!sym(names(raster_sf)[1])), decreasing = TRUE))[1],
      pixel_count = n(),
      .groups = 'drop'
    ) %>%
    filter(!is.na(majority_ecosystem))
  
  # Join back to hexagon geometries
  result <- hex_grid %>%
    left_join(hex_summary, by = "hex_id") %>%
    filter(!is.na(majority_ecosystem))
  
  return(result)
}

# Function to create sample ecosystem raster (if you don't have one)
create_sample_ecosystem_raster <- function() {
  # Create a sample raster with ecosystem types
  # You can replace this with your actual raster loading code
  
  # Define extent (example: somewhere in the western US)
  ext <- c(-120, -115, 35, 40)  # xmin, xmax, ymin, ymax
  
  # Create raster
  r <- terra::rast(extent = ext, resolution = 0.01, crs = "EPSG:4326")
  
  # Fill with sample ecosystem data
  set.seed(123)
  ecosystem_values <- sample(1:8, ncell(r), replace = TRUE, 
                           prob = c(0.2, 0.15, 0.15, 0.1, 0.1, 0.1, 0.1, 0.1))
  values(r) <- ecosystem_values
  names(r) <- "ecosystem_type"
  
  return(r)
}

# Function to get ecosystem colors and names
get_ecosystem_info <- function() {
  ecosystem_names <- c(
    "1" = "Forest - Coniferous",
    "2" = "Forest - Deciduous", 
    "3" = "Grassland",
    "4" = "Shrubland",
    "5" = "Wetland",
    "6" = "Agricultural",
    "7" = "Urban",
    "8" = "Water"
  )
  
  ecosystem_colors <- c(
    "1" = "#0d5016", # Dark green for coniferous
    "2" = "#228B22", # Forest green for deciduous
    "3" = "#9ACD32", # Yellow green for grassland
    "4" = "#DEB887", # Burlywood for shrubland
    "5" = "#4682B4", # Steel blue for wetland
    "6" = "#DAA520", # Goldenrod for agricultural
    "7" = "#696969", # Dim gray for urban
    "8" = "#0000FF"  # Blue for water
  )
  
  return(list(names = ecosystem_names, colors = ecosystem_colors))
}

# Main function to create the interactive map
create_ecosystem_hexmap <- function(raster_file = NULL) {
  
  # Load or create raster data
  if (is.null(raster_file)) {
    cat("No raster file provided. Creating sample data...\n")
    ecosystem_raster <- create_sample_ecosystem_raster()
  } else {
    cat("Loading raster file:", raster_file, "\n")
    ecosystem_raster <- terra::rast(raster_file)
  }
  
  # Get ecosystem information
  eco_info <- get_ecosystem_info()
  
  # Define the study area extent
  raster_extent <- terra::ext(ecosystem_raster)
  study_bbox <- st_bbox(c(xmin = raster_extent[1], ymin = raster_extent[3], 
                         xmax = raster_extent[2], ymax = raster_extent[4]),
                       crs = st_crs(4326))
  study_area <- st_as_sfc(study_bbox)
  
  # Create hexagonal grids at different zoom levels
  cat("Creating hexagonal grids...\n")
  hex_large <- create_hex_grid(study_area, cell_size = 0.1)    # For zoom levels 1-8
  hex_medium <- create_hex_grid(study_area, cell_size = 0.05)  # For zoom levels 9-11
  hex_small <- create_hex_grid(study_area, cell_size = 0.02)   # For zoom levels 12+
  
  # Aggregate ecosystem data to each hexagonal grid
  cat("Aggregating data to hexagons...\n")
  hex_data_large <- aggregate_to_hexagons(ecosystem_raster, hex_large)
  hex_data_medium <- aggregate_to_hexagons(ecosystem_raster, hex_medium)
  hex_data_small <- aggregate_to_hexagons(ecosystem_raster, hex_small)
  
  # Add ecosystem names and colors
  for (hex_data in list(hex_data_large, hex_data_medium, hex_data_small)) {
    hex_data$ecosystem_name <- eco_info$names[hex_data$majority_ecosystem]
    hex_data$ecosystem_color <- eco_info$colors[hex_data$majority_ecosystem]
  }
  
  # Create the leaflet map
  cat("Creating interactive map...\n")
  map <- leaflet() %>%
    addProviderTiles(providers$CartoDB.Positron, group = "Light") %>%
    addProviderTiles(providers$OpenStreetMap, group = "OpenStreetMap") %>%
    addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
    
    # Add hexagon layers for different zoom levels
    addPolygons(
      data = hex_data_large,
      fillColor = ~ecosystem_color,
      fillOpacity = 0.7,
      color = "white",
      weight = 0.5,
      popup = ~paste0(
        "<b>Ecosystem:</b> ", ecosystem_name, "<br>",
        "<b>Pixel Count:</b> ", pixel_count
      ),
      group = "Large Hexagons (Zoom 1-8)"
    ) %>%
    
    addPolygons(
      data = hex_data_medium,
      fillColor = ~ecosystem_color,
      fillOpacity = 0.7,
      color = "white",
      weight = 0.5,
      popup = ~paste0(
        "<b>Ecosystem:</b> ", ecosystem_name, "<br>",
        "<b>Pixel Count:</b> ", pixel_count
      ),
      group = "Medium Hexagons (Zoom 9-11)"
    ) %>%
    
    addPolygons(
      data = hex_data_small,
      fillColor = ~ecosystem_color,
      fillOpacity = 0.7,
      color = "white",
      weight = 0.5,
      popup = ~paste0(
        "<b>Ecosystem:</b> ", ecosystem_name, "<br>",
        "<b>Pixel Count:</b> ", pixel_count
      ),
      group = "Small Hexagons (Zoom 12+)"
    ) %>%
    
    # Add layer control
    addLayersControl(
      baseGroups = c("Light", "OpenStreetMap", "Satellite"),
      overlayGroups = c("Large Hexagons (Zoom 1-8)", 
                       "Medium Hexagons (Zoom 9-11)", 
                       "Small Hexagons (Zoom 12+)"),
      options = layersControlOptions(collapsed = FALSE)
    ) %>%
    
    # Add legend
    addLegend(
      "bottomright",
      colors = eco_info$colors,
      labels = eco_info$names,
      title = "Ecosystem Types",
      opacity = 0.7
    ) %>%
    
    # Set initial view
    fitBounds(
      lng1 = raster_extent[1], lat1 = raster_extent[3],
      lng2 = raster_extent[2], lat2 = raster_extent[4]
    )
  
  # Add JavaScript to control layer visibility based on zoom level
  map <- map %>%
    htmlwidgets::onRender("
      function(el, x) {
        var map = this;
        
        // Function to update layers based on zoom level
        function updateLayers() {
          var zoom = map.getZoom();
          
          if (zoom <= 8) {
            map.addLayer(map._layers[Object.keys(map._layers).find(key => 
              map._layers[key].options && map._layers[key].options.group === 'Large Hexagons (Zoom 1-8)')]);
            map.removeLayer(map._layers[Object.keys(map._layers).find(key => 
              map._layers[key].options && map._layers[key].options.group === 'Medium Hexagons (Zoom 9-11)')]);
            map.removeLayer(map._layers[Object.keys(map._layers).find(key => 
              map._layers[key].options && map._layers[key].options.group === 'Small Hexagons (Zoom 12+)')]);
          } else if (zoom <= 11) {
            map.removeLayer(map._layers[Object.keys(map._layers).find(key => 
              map._layers[key].options && map._layers[key].options.group === 'Large Hexagons (Zoom 1-8)')]);
            map.addLayer(map._layers[Object.keys(map._layers).find(key => 
              map._layers[key].options && map._layers[key].options.group === 'Medium Hexagons (Zoom 9-11)')]);
            map.removeLayer(map._layers[Object.keys(map._layers).find(key => 
              map._layers[key].options && map._layers[key].options.group === 'Small Hexagons (Zoom 12+)')]);
          } else {
            map.removeLayer(map._layers[Object.keys(map._layers).find(key => 
              map._layers[key].options && map._layers[key].options.group === 'Large Hexagons (Zoom 1-8)')]);
            map.removeLayer(map._layers[Object.keys(map._layers).find(key => 
              map._layers[key].options && map._layers[key].options.group === 'Medium Hexagons (Zoom 9-11)')]);
            map.addLayer(map._layers[Object.keys(map._layers).find(key => 
              map._layers[key].options && map._layers[key].options.group === 'Small Hexagons (Zoom 12+)')]);
          }
        }
        
        // Initial layer setup
        updateLayers();
        
        // Listen for zoom changes
        map.on('zoomend', updateLayers);
      }
    ")
  
  return(map)
}

# Example usage:
# If you have a raster file, use:
# map <- create_ecosystem_hexmap("path/to/your/ecosystem_raster.tif")

# For demo with sample data:
cat("Creating ecosystem hexagonal map...\n")
map <- create_ecosystem_hexmap()

# Display the map
print(map)

# Save the map to an HTML file
cat("Saving map to ecosystem_hexmap.html...\n")
saveWidget(map, "ecosystem_hexmap.html", selfcontained = TRUE)

cat("Map created successfully!\n")
cat("Open 'ecosystem_hexmap.html' in your browser to view the interactive map.\n")