# Demo Output and Usage Guide

## What You'll Get

When you run the ecosystem hexagonal mapping scripts, you'll create an interactive HTML map with the following features:

### 🎯 Key Features Demonstrated

1. **Zoom-Responsive Hexagons**
   - Zoom levels 1-8: Large hexagons for overview
   - Zoom levels 9-11: Medium hexagons for intermediate detail  
   - Zoom levels 12+: Small hexagons for detailed analysis

2. **Interactive Elements**
   - Click any hexagon to see a popup with:
     - Ecosystem type name
     - Ecosystem code number
     - Number of pixels aggregated
     - Hexagon center coordinates

3. **Multiple Base Maps**
   - Light theme (CartoDB Positron)
   - Street map (OpenStreetMap)
   - Satellite imagery (Esri WorldImagery)
   - Topographic map (Esri WorldTopoMap)

4. **Legend and Controls**
   - Color-coded legend for all ecosystem types
   - Layer control panel for base map selection
   - Zoom level indicator in top-left corner

## Example Workflow

### Step 1: Prepare Your Environment
```r
# Install packages
source("install_packages.R")
```

### Step 2: Quick Demo with Sample Data
```r
# Load the advanced script
source("advanced_ecosystem_hexmap.R")
# This automatically creates and saves a demo map
```

### Step 3: Use Your Own Data
```r
# Edit ecosystem information first
source("use_your_own_raster.R")

# Create map with your raster
my_map <- create_your_ecosystem_map("path/to/your/ecosystem.tif")

# Save to HTML file
saveWidget(my_map, "my_ecosystem_map.html", selfcontained = TRUE)
```

## Sample Output Structure

Your HTML file will contain:
- Fully interactive Leaflet map
- All necessary JavaScript and CSS embedded
- No external dependencies (selfcontained = TRUE)
- Responsive design that works on desktop and mobile

## Expected Console Output

When running the scripts, you'll see progress messages like:

```
=== Advanced Ecosystem Hexagonal Map ===
Creating sample ecosystem data...
Creating hexagonal grids at multiple resolutions...
Aggregating raster data to hexagons...
Building interactive Leaflet map...
Saving map to 'advanced_ecosystem_hexmap.html'...

Interactive map created successfully!
Features:
- Automatic hexagon size adjustment based on zoom level
- Multiple base map options
- Zoom level indicator
- Detailed popups with ecosystem information
- Optimized performance with proper layer management

Open 'advanced_ecosystem_hexmap.html' in your browser to explore!
```

## File Outputs

After running the scripts, you'll have:

1. **advanced_ecosystem_hexmap.html** - Main interactive map
2. **ecosystem_hexmap.html** - Basic version (if you ran the simple script)
3. **my_ecosystem_map.html** - Your custom map (if using own data)

## Browser Compatibility

The generated maps work in all modern browsers:
- Chrome/Chromium
- Firefox
- Safari
- Edge

## Performance Expectations

### Sample Data Performance
- Processing time: 30-60 seconds
- File size: ~500KB - 2MB
- Smooth interaction with all zoom levels

### Real Data Performance (varies by raster size)
- Small raster (< 1M pixels): 1-2 minutes
- Medium raster (1-10M pixels): 2-10 minutes  
- Large raster (> 10M pixels): Consider preprocessing

## Customization Examples

### Custom Ecosystem Colors
```r
ecosystem_colors <- c(
  "1" = "#2d5016",  # Dark forest green
  "2" = "#8fbc8f",  # Light forest green
  "3" = "#daa520",  # Golden grassland
  "4" = "#cd853f",  # Sandy shrubland
  "5" = "#4682b4",  # Steel blue wetland
  "6" = "#8b4513",  # Saddle brown for agricultural
  "7" = "#708090",  # Slate gray for urban
  "8" = "#191970"   # Midnight blue for water
)
```

### Custom Zoom Thresholds
```r
# For global-scale data
zoom_thresholds = c(6, 10)
hex_sizes = c(2.0, 1.0, 0.5)

# For local-scale data
zoom_thresholds = c(12, 15)
hex_sizes = c(0.01, 0.005, 0.002)
```

## Troubleshooting Common Issues

### 1. Installation Problems
If package installation fails:
```r
# Try installing packages individually
install.packages("leaflet")
install.packages("sf")
install.packages("terra")
```

### 2. Memory Issues with Large Rasters
```r
# Resample to lower resolution first
library(terra)
r <- rast("large_raster.tif")
r_resampled <- aggregate(r, fact=5)  # Reduce by factor of 5
writeRaster(r_resampled, "smaller_raster.tif")
```

### 3. CRS Problems
```r
# Check and fix coordinate system
library(terra)
r <- rast("your_raster.tif")
crs(r)  # Check current CRS

# If undefined, set it
crs(r) <- "EPSG:4326"

# If wrong, reproject it
r_reprojected <- project(r, "EPSG:4326")
```

## Next Steps

1. **Start with the demo**: Run `advanced_ecosystem_hexmap.R` to see how it works
2. **Examine your data**: Check raster values, CRS, and extent
3. **Customize ecosystem info**: Update names and colors to match your data
4. **Test with subset**: Use a small portion of your data first
5. **Optimize settings**: Adjust hexagon sizes and zoom thresholds
6. **Create final map**: Process your full dataset

## Integration with Other Tools

The generated HTML maps can be:
- Embedded in websites or presentations
- Shared via email or cloud storage
- Integrated into R Markdown documents
- Used in Shiny applications
- Converted to screenshots for publications

---

**Ready to get started?** Follow the Quick Start guide in the README.md file!