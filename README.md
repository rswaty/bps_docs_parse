# Ecosystem Hexagonal Mapping with R and Leaflet

This project creates interactive Leaflet maps that display ecosystem data using hexagonal aggregation. The hexagon size automatically adjusts based on zoom level, providing an optimal viewing experience at different scales.

## 🌟 Features

- **Zoom-responsive hexagons**: Hexagon size changes automatically as you zoom in/out
- **Majority ecosystem aggregation**: Each hexagon displays the most common ecosystem within its boundaries
- **Interactive popups**: Click hexagons to see detailed ecosystem information
- **Multiple base maps**: Choose from light, satellite, street, and topographic base layers
- **Customizable**: Easy to adapt for your own ecosystem raster data
- **Performance optimized**: Efficient layer management for smooth interaction

## 📋 Requirements

### R Packages
- `leaflet` - Interactive maps
- `sf` - Spatial features and operations
- `terra` - Raster data handling
- `dplyr` - Data manipulation
- `htmlwidgets` - Save interactive maps as HTML
- `RColorBrewer` - Color palettes
- `viridis` - Color palettes

### System Requirements
- R version 4.0 or higher
- GDAL libraries (usually installed with sf package)

## 🚀 Quick Start

### 1. Install Required Packages
```r
source("install_packages.R")
```

### 2. Run with Sample Data
```r
source("advanced_ecosystem_hexmap.R")
```
This will create a demo map with synthetic ecosystem data and save it as `advanced_ecosystem_hexmap.html`.

### 3. Use Your Own Data
```r
# Edit the ecosystem info in use_your_own_raster.R first
source("use_your_own_raster.R")
my_map <- create_your_ecosystem_map("path/to/your/ecosystem_raster.tif")
```

## 📁 File Structure

```
├── install_packages.R           # Install required R packages
├── ecosystem_hexmap.R          # Basic hexagonal mapping implementation
├── advanced_ecosystem_hexmap.R # Enhanced version with better features
├── use_your_own_raster.R      # Guide for using your own raster data
└── README.md                  # This file
```

## 🗺️ How It Works

### 1. Hexagonal Grid Creation
The script creates three hexagonal grids at different resolutions:
- **Large hexagons** (zoom levels 1-8): For overview display
- **Medium hexagons** (zoom levels 9-11): For intermediate detail
- **Small hexagons** (zoom levels 12+): For detailed view

### 2. Ecosystem Aggregation
For each hexagon, the script:
- Extracts all raster pixels within the hexagon boundary
- Calculates the majority (modal) ecosystem type
- Counts the number of pixels for additional information

### 3. Interactive Display
The Leaflet map automatically switches between hexagon layers based on zoom level using JavaScript, providing a seamless user experience.

## 🎨 Customization

### Ecosystem Types and Colors
Modify the `get_ecosystem_info()` function to match your data:

```r
ecosystem_names <- c(
  "1" = "Your Ecosystem Type 1",
  "2" = "Your Ecosystem Type 2",
  # ... add more as needed
)

ecosystem_colors <- c(
  "1" = "#color1", 
  "2" = "#color2",
  # ... corresponding colors
)
```

### Hexagon Sizes
Adjust hexagon sizes (in degrees) for your study area:

```r
hex_sizes = c(0.1, 0.05, 0.02)  # Large, medium, small
```

### Zoom Thresholds
Control when hexagon layers switch:

```r
zoom_thresholds = c(8, 11)  # Switch points between the three layers
```

## 📊 Input Data Requirements

Your ecosystem raster should have:
- **Integer values** representing ecosystem codes
- **Defined CRS** (coordinate reference system)
- **Consistent coding** (same value = same ecosystem type)

### Supported Formats
- GeoTIFF (.tif, .tiff)
- NetCDF (.nc)
- ESRI Grid
- Most GDAL-supported raster formats

## 💡 Usage Examples

### Basic Usage
```r
# With sample data
map <- create_advanced_ecosystem_hexmap()

# With your data
map <- create_advanced_ecosystem_hexmap("your_ecosystem_raster.tif")

# Save to HTML
saveWidget(map, "my_ecosystem_map.html", selfcontained = TRUE)
```

### Advanced Customization
```r
map <- create_advanced_ecosystem_hexmap(
  raster_file = "your_data.tif",
  zoom_thresholds = c(9, 12),           # Custom zoom levels
  hex_sizes = c(0.15, 0.08, 0.03)      # Custom hex sizes
)
```

## 🔧 Troubleshooting

### Common Issues

1. **Package installation fails**
   - Try installing packages individually
   - Check if you have admin rights
   - Update R to the latest version

2. **GDAL errors**
   - Ensure sf package is properly installed
   - On Linux: `sudo apt-get install gdal-bin libgdal-dev`
   - On Mac: `brew install gdal`

3. **Large raster performance**
   - Consider resampling to lower resolution first
   - Start with larger hexagon sizes
   - Test with a subset of your data

4. **CRS issues**
   - Ensure your raster has a defined coordinate system
   - Use `terra::crs(your_raster)` to check
   - Reproject if necessary: `terra::project(your_raster, "EPSG:4326")`

### Performance Tips

- For large datasets, start with:
  - Larger hexagon sizes (0.2, 0.1, 0.05)
  - Fewer zoom levels
  - Lower resolution rasters

- Test performance with a subset before processing full dataset

## 🤝 Contributing

Feel free to improve this code! Some ideas:
- Add support for multiple raster layers
- Implement custom aggregation functions (mean, median, etc.)
- Add animation between zoom levels
- Include additional statistical information in popups

## 📄 License

This project is open source. Feel free to use and modify for your research or projects.

## 🙏 Acknowledgments

Built using:
- [Leaflet](https://leafletjs.com/) for interactive mapping
- [R sf package](https://r-spatial.github.io/sf/) for spatial operations
- [terra package](https://rspatial.org/terra/) for raster processing

---

**Need help?** Check the comments in the R scripts or create an issue describing your problem along with your data specifications.

**Have improvements?** Pull requests are welcome!