// ===================================================================
// LANDFIRE Multi-Scale Hexagonal Dashboard
// Interactive visualization with zoom-based hexagon resolution switching
// ===================================================================

// Load LANDFIRE Vegetation Collections
var bps = ee.ImageCollection("projects/sat-io/open-datasets/landfire/VEGETATION/BPS");
var evc = ee.ImageCollection("projects/sat-io/open-datasets/landfire/VEGETATION/EVC");
var evh = ee.ImageCollection("projects/sat-io/open-datasets/landfire/VEGETATION/EVH");
var evt = ee.ImageCollection("projects/sat-io/open-datasets/landfire/VEGETATION/EVT");
var sclass = ee.ImageCollection("projects/sat-io/open-datasets/landfire/VEGETATION/SCLASS");
var vcc = ee.ImageCollection("projects/sat-io/open-datasets/landfire/VEGETATION/VCC");
var vdep = ee.ImageCollection("projects/sat-io/open-datasets/landfire/VEGETATION/VDEP");

// Get most recent images from each collection
var bpsImage = bps.sort('system:time_start', false).first();
var evcImage = evc.sort('system:time_start', false).first();
var evhImage = evh.sort('system:time_start', false).first();
var evtImage = evt.sort('system:time_start', false).first();
var sclassImage = sclass.sort('system:time_start', false).first();
var vccImage = vcc.sort('system:time_start', false).first();
var vdepImage = vdep.sort('system:time_start', false).first();

// Define visualization parameters for different datasets
var visParams = {
  'BPS': {min: 0, max: 5000, palette: ['#d73027', '#f46d43', '#fdae61', '#fee08b', '#e6f598', '#abdda4', '#66c2a5', '#3288bd']},
  'EVC': {min: 0, max: 100, palette: ['#ffffcc', '#c7e9b4', '#7fcdbb', '#41b6c4', '#1d91c0', '#225ea8', '#0c2c84']},
  'EVH': {min: 0, max: 30, palette: ['#ffffb2', '#fecc5c', '#fd8d3c', '#f03b20', '#bd0026']},
  'EVT': {min: 0, max: 7000, palette: ['#8e0152', '#c51b7d', '#de77ae', '#f1b6da', '#fde0ef', '#e6f5d0', '#b8e186', '#7fbc41', '#4d9221', '#276419']},
  'SCLASS': {min: 0, max: 5, palette: ['#fee5d9', '#fcae91', '#fb6a4a', '#de2d26', '#a50f15']},
  'VCC': {min: 0, max: 100, palette: ['#f7fcf0', '#e0f3db', '#ccebc5', '#a8ddb5', '#7bccc4', '#4eb3d3', '#2b8cbe', '#08589e']},
  'VDEP': {min: 0, max: 100, palette: ['#fff7ec', '#fee8c8', '#fdd49e', '#fdbb84', '#fc8d59', '#ef6548', '#d7301f', '#990000']}
};

// Function to create hexagonal grid using H3
function createH3Grid(geometry, resolution) {
  // Create a feature collection of hexagons covering the geometry
  var hexagons = ee.Algorithms.H3.polyfill(geometry, resolution, ee.Number(1000));
  
  return ee.FeatureCollection(hexagons.map(function(hex) {
    var hexGeom = ee.Algorithms.H3.h3ToGeoBoundary(hex);
    return ee.Feature(ee.Geometry.Polygon(hexGeom), {h3_index: hex});
  }));
}

// Function to aggregate raster values to hexagons (majority value)
function aggregateToHexagons(image, hexagons, bandName) {
  return hexagons.map(function(hex) {
    var values = image.select(bandName).reduceRegion({
      reducer: ee.Reducer.mode(),
      geometry: hex.geometry(),
      scale: 30,
      maxPixels: 1e9
    });
    
    return hex.set({
      'majority_value': values.get(bandName),
      'band_name': bandName
    });
  });
}

// Function to style hexagons based on values
function styleHexagons(hexFeatures, dataset) {
  var vis = visParams[dataset];
  return hexFeatures.map(function(feature) {
    var value = ee.Number(feature.get('majority_value'));
    var normalized = value.subtract(vis.min).divide(vis.max - vis.min);
    var paletteIndex = normalized.multiply(vis.palette.length - 1).round().int();
    var color = ee.List(vis.palette).get(paletteIndex);
    
    return feature.set({
      'style': {
        'color': color,
        'fillOpacity': 0.7,
        'width': 1
      }
    });
  });
}

// Create the main map
var map = ui.Map();
map.setCenter(-100, 40, 6); // Center on US

// Create UI elements
var titleLabel = ui.Label({
  value: 'LANDFIRE Multi-Scale Hexagonal Dashboard',
  style: {fontSize: '24px', fontWeight: 'bold', margin: '10px'}
});

var descriptionLabel = ui.Label({
  value: 'Interactive visualization of LANDFIRE vegetation data with adaptive hexagonal grids. Zoom to see different resolutions.',
  style: {fontSize: '14px', margin: '10px', maxWidth: '400px'}
});

// Dataset selector
var datasetSelect = ui.Select({
  items: ['BPS', 'EVC', 'EVH', 'EVT', 'SCLASS', 'VCC', 'VDEP'],
  value: 'EVT',
  placeholder: 'Select dataset...',
  style: {margin: '10px'}
});

// Resolution info panel
var resolutionLabel = ui.Label({
  value: 'Current H3 Resolution: 5',
  style: {fontSize: '12px', margin: '10px'}
});

var zoomLabel = ui.Label({
  value: 'Map Zoom: 6',
  style: {fontSize: '12px', margin: '10px'}
});

// Legend panel
var legendPanel = ui.Panel({
  style: {
    position: 'bottom-left',
    padding: '8px',
    backgroundColor: 'rgba(255, 255, 255, 0.8)'
  }
});

// Function to create legend
function createLegend(dataset) {
  legendPanel.clear();
  var vis = visParams[dataset];
  var legendTitle = ui.Label({
    value: dataset + ' Legend',
    style: {fontWeight: 'bold', fontSize: '14px', margin: '0 0 8px 0'}
  });
  legendPanel.add(legendTitle);
  
  // Create color bar
  var colorBar = ui.Thumbnail({
    image: ee.Image.pixelLonLat().select(0).rename('color'),
    params: {
      bbox: [0, 0, 1, 0.1],
      dimensions: '200x20',
      format: 'png',
      min: 0,
      max: 1,
      palette: vis.palette
    },
    style: {margin: '0px'}
  });
  
  var minLabel = ui.Label({value: vis.min.toString(), style: {fontSize: '10px'}});
  var maxLabel = ui.Label({value: vis.max.toString(), style: {fontSize: '10px'}});
  
  var labelPanel = ui.Panel({
    widgets: [minLabel, maxLabel],
    layout: ui.Panel.Layout.flow('horizontal'),
    style: {justifyContent: 'space-between', width: '200px'}
  });
  
  legendPanel.add(colorBar);
  legendPanel.add(labelPanel);
}

// Function to determine H3 resolution based on zoom level
function getH3ResolutionFromZoom(zoomLevel) {
  if (zoomLevel <= 6) return 3;
  if (zoomLevel <= 8) return 4;
  if (zoomLevel <= 10) return 5;
  if (zoomLevel <= 12) return 6;
  if (zoomLevel <= 14) return 7;
  return 8;
}

// Function to update visualization
function updateVisualization() {
  var selectedDataset = datasetSelect.getValue();
  var currentZoom = map.getZoom();
  var h3Resolution = getH3ResolutionFromZoom(currentZoom);
  
  // Update labels
  resolutionLabel.setValue('Current H3 Resolution: ' + h3Resolution);
  zoomLabel.setValue('Map Zoom: ' + currentZoom);
  
  // Get the selected image
  var selectedImage;
  switch(selectedDataset) {
    case 'BPS': selectedImage = bpsImage; break;
    case 'EVC': selectedImage = evcImage; break;
    case 'EVH': selectedImage = evhImage; break;
    case 'EVT': selectedImage = evtImage; break;
    case 'SCLASS': selectedImage = sclassImage; break;
    case 'VCC': selectedImage = vccImage; break;
    case 'VDEP': selectedImage = vdepImage; break;
    default: selectedImage = evtImage;
  }
  
  // Clear existing layers
  map.layers().reset();
  
  // Get current map bounds for creating hexagons
  var bounds = map.getBounds();
  if (bounds) {
    var geometry = ee.Geometry.Rectangle([bounds[0], bounds[1], bounds[2], bounds[3]]);
    
    // Create hexagonal grid
    var hexagons = createH3Grid(geometry, h3Resolution);
    
    // Aggregate data to hexagons
    var aggregatedHexagons = aggregateToHexagons(selectedImage, hexagons, selectedImage.bandNames().get(0));
    
    // Style hexagons
    var styledHexagons = styleHexagons(aggregatedHexagons, selectedDataset);
    
    // Add hexagons to map
    map.addLayer(styledHexagons, {}, 'Hexagonal ' + selectedDataset);
    
    // Also add the original raster for comparison (with low opacity)
    map.addLayer(selectedImage, visParams[selectedDataset], 'Original ' + selectedDataset, false, 0.3);
  }
  
  // Update legend
  createLegend(selectedDataset);
}

// Event handlers
datasetSelect.onChange(updateVisualization);

// Map zoom change handler
var zoomChangeHandler = function() {
  var newZoom = map.getZoom();
  var newResolution = getH3ResolutionFromZoom(newZoom);
  var currentResolution = parseInt(resolutionLabel.getValue().split(': ')[1]);
  
  zoomLabel.setValue('Map Zoom: ' + newZoom);
  
  // Only update if resolution changed to avoid unnecessary recomputation
  if (newResolution !== currentResolution) {
    updateVisualization();
  }
};

// Debounce zoom changes to avoid too frequent updates
var zoomTimeout;
map.onChangeZoom(function() {
  if (zoomTimeout) {
    clearTimeout(zoomTimeout);
  }
  zoomTimeout = setTimeout(zoomChangeHandler, 500);
});

// Map bounds change handler (for panning)
var boundsTimeout;
map.onChangeBounds(function() {
  if (boundsTimeout) {
    clearTimeout(boundsTimeout);
  }
  boundsTimeout = setTimeout(updateVisualization, 1000);
});

// Create control panel
var controlPanel = ui.Panel({
  widgets: [
    titleLabel,
    descriptionLabel,
    datasetSelect,
    resolutionLabel,
    zoomLabel,
    ui.Label({
      value: 'Instructions:\n• Select a dataset from dropdown\n• Zoom in/out to see different hexagon sizes\n• Pan to load new areas\n• Toggle layers in layer manager',
      style: {fontSize: '12px', margin: '10px', whiteSpace: 'pre'}
    })
  ],
  style: {
    width: '350px',
    position: 'top-left',
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    padding: '10px'
  }
});

// Add panels to map
map.add(controlPanel);
map.add(legendPanel);

// Set up the UI
ui.root.clear();
ui.root.add(map);

// Initial visualization
updateVisualization();

// Add some sample locations for users to explore
var sampleLocations = [
  {name: 'Yellowstone National Park', coords: [-110.5, 44.6], zoom: 10},
  {name: 'Great Smoky Mountains', coords: [-83.5, 35.6], zoom: 10},
  {name: 'California Central Valley', coords: [-121.0, 37.0], zoom: 9},
  {name: 'Florida Everglades', coords: [-80.9, 25.3], zoom: 10},
  {name: 'Pacific Northwest Forests', coords: [-123.0, 47.0], zoom: 9}
];

// Add sample location buttons
var locationPanel = ui.Panel({
  widgets: [ui.Label({value: 'Sample Locations:', style: {fontWeight: 'bold', fontSize: '12px'}})],
  style: {
    position: 'top-right',
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    padding: '8px',
    width: '200px'
  }
});

sampleLocations.forEach(function(location) {
  var button = ui.Button({
    label: location.name,
    onClick: function() {
      map.setCenter(location.coords[0], location.coords[1], location.zoom);
    },
    style: {margin: '2px', fontSize: '10px'}
  });
  locationPanel.add(button);
});

map.add(locationPanel);

print('LANDFIRE Multi-Scale Hexagonal Dashboard loaded successfully!');
print('Use the controls to explore different vegetation datasets with adaptive hexagonal grids.');