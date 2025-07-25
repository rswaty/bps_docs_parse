// ===================================================================
// LANDFIRE Multi-Scale Hexagonal Dashboard - CORRECTED VERSION
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

// Function to create regular grid (since H3 might not be available)
function createRegularGrid(geometry, resolution) {
  // Create a regular square grid as fallback
  var bounds = geometry.bounds();
  var coords = ee.List(bounds.coordinates().get(0));
  var xmin = ee.Number(ee.List(coords.get(0)).get(0));
  var ymin = ee.Number(ee.List(coords.get(0)).get(1));
  var xmax = ee.Number(ee.List(coords.get(2)).get(0));
  var ymax = ee.Number(ee.List(coords.get(2)).get(1));
  
  // Calculate grid size based on resolution
  var gridSize = ee.Number(0.1).divide(ee.Number(resolution).add(1));
  
  var gridFeatures = ee.List([]);
  
  // Create a simple grid - this is a simplified version
  var xSteps = xmax.subtract(xmin).divide(gridSize).round();
  var ySteps = ymax.subtract(ymin).divide(gridSize).round();
  
  // Limit grid size for performance
  xSteps = ee.Number(ee.Algorithms.If(xSteps.gt(50), 50, xSteps));
  ySteps = ee.Number(ee.Algorithms.If(ySteps.gt(50), 50, ySteps));
  
  var xStep = xmax.subtract(xmin).divide(xSteps);
  var yStep = ymax.subtract(ymin).divide(ySteps);
  
  // Generate grid cells
  var xRange = ee.List.sequence(0, xSteps.subtract(1));
  var yRange = ee.List.sequence(0, ySteps.subtract(1));
  
  var features = xRange.map(function(x) {
    x = ee.Number(x);
    return yRange.map(function(y) {
      y = ee.Number(y);
      var x1 = xmin.add(x.multiply(xStep));
      var y1 = ymin.add(y.multiply(yStep));
      var x2 = x1.add(xStep);
      var y2 = y1.add(yStep);
      
      var cell = ee.Geometry.Rectangle([x1, y1, x2, y2]);
      return ee.Feature(cell, {grid_id: x.multiply(1000).add(y)});
    });
  }).flatten();
  
  return ee.FeatureCollection(features);
}

// Function to aggregate raster values to grid cells (majority value)
function aggregateToGrid(image, gridCells) {
  return gridCells.map(function(cell) {
    var values = image.reduceRegion({
      reducer: ee.Reducer.mode(),
      geometry: cell.geometry(),
      scale: 30,
      maxPixels: 1e6,
      bestEffort: true
    });
    
    var bandName = image.bandNames().get(0);
    return cell.set({
      'majority_value': values.get(bandName),
      'band_name': bandName
    });
  });
}

// Create the main map
var map = ui.Map();
map.setCenter(-100, 40, 6);

// Create UI elements
var titleLabel = ui.Label({
  value: 'LANDFIRE Multi-Scale Grid Dashboard',
  style: {fontSize: '24px', fontWeight: 'bold', margin: '10px'}
});

var descriptionLabel = ui.Label({
  value: 'Interactive visualization of LANDFIRE vegetation data with adaptive grids. Zoom to see different resolutions.',
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
  value: 'Current Grid Resolution: 3',
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
  
  // Create simple legend with min/max values
  var minLabel = ui.Label({
    value: 'Min: ' + vis.min.toString(),
    style: {fontSize: '10px', margin: '2px'}
  });
  var maxLabel = ui.Label({
    value: 'Max: ' + vis.max.toString(), 
    style: {fontSize: '10px', margin: '2px'}
  });
  
  legendPanel.add(minLabel);
  legendPanel.add(maxLabel);
}

// Function to determine grid resolution based on zoom level
function getGridResolutionFromZoom(zoomLevel) {
  if (zoomLevel <= 6) return 1;
  if (zoomLevel <= 8) return 2;
  if (zoomLevel <= 10) return 3;
  if (zoomLevel <= 12) return 4;
  if (zoomLevel <= 14) return 5;
  return 6;
}

// Function to update visualization
function updateVisualization() {
  var selectedDataset = datasetSelect.getValue();
  var currentZoom = map.getZoom();
  var gridResolution = getGridResolutionFromZoom(currentZoom);
  
  // Update labels
  resolutionLabel.setValue('Current Grid Resolution: ' + gridResolution);
  zoomLabel.setValue('Map Zoom: ' + currentZoom);
  
  // Get the selected image
  var selectedImage;
  if (selectedDataset === 'BPS') {
    selectedImage = bpsImage;
  } else if (selectedDataset === 'EVC') {
    selectedImage = evcImage;
  } else if (selectedDataset === 'EVH') {
    selectedImage = evhImage;
  } else if (selectedDataset === 'EVT') {
    selectedImage = evtImage;
  } else if (selectedDataset === 'SCLASS') {
    selectedImage = sclassImage;
  } else if (selectedDataset === 'VCC') {
    selectedImage = vccImage;
  } else if (selectedDataset === 'VDEP') {
    selectedImage = vdepImage;
  } else {
    selectedImage = evtImage;
  }
  
  // Clear existing layers
  map.layers().reset();
  
  // Add the original raster
  map.addLayer(selectedImage, visParams[selectedDataset], selectedDataset + ' (Original)');
  
  // Get current map bounds for creating grid
  var bounds = map.getBounds();
  if (bounds && bounds.length === 4) {
    var geometry = ee.Geometry.Rectangle(bounds);
    
    // Create grid
    var gridCells = createRegularGrid(geometry, gridResolution);
    
    // Aggregate data to grid cells
    var aggregatedCells = aggregateToGrid(selectedImage, gridCells);
    
    // Style the grid cells
    var styledCells = aggregatedCells.map(function(cell) {
      var value = ee.Number(cell.get('majority_value'));
      return cell.set('style', {
        'fillOpacity': 0.6,
        'width': 1,
        'color': '#000000'
      });
    });
    
    // Add grid to map with lower opacity so original shows through
    map.addLayer(styledCells.style({
      fillColor: 'red'
    }), {opacity: 0.5}, selectedDataset + ' (Grid)');
  }
  
  // Update legend
  createLegend(selectedDataset);
}

// Event handlers
datasetSelect.onChange(updateVisualization);

// Map zoom change handler with debouncing
var updateTimeout;
function debouncedUpdate() {
  if (updateTimeout) {
    clearTimeout(updateTimeout);
  }
  updateTimeout = setTimeout(function() {
    zoomLabel.setValue('Map Zoom: ' + map.getZoom());
    updateVisualization();
  }, 1000);
}

// Add map event listeners
map.onChangeZoom(debouncedUpdate);
map.onChangeBounds(debouncedUpdate);

// Create control panel
var controlPanel = ui.Panel({
  widgets: [
    titleLabel,
    descriptionLabel,
    datasetSelect,
    resolutionLabel,
    zoomLabel,
    ui.Label({
      value: 'Instructions:\n• Select a dataset from dropdown\n• Zoom in/out to see different grid sizes\n• Pan to load new areas',
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

// Sample locations for users to explore
var sampleLocations = [
  {name: 'Yellowstone', coords: [-110.5, 44.6], zoom: 10},
  {name: 'Great Smokies', coords: [-83.5, 35.6], zoom: 10},
  {name: 'Central Valley CA', coords: [-121.0, 37.0], zoom: 9},
  {name: 'Everglades FL', coords: [-80.9, 25.3], zoom: 10},
  {name: 'Pacific NW', coords: [-123.0, 47.0], zoom: 9}
];

// Add sample location buttons
var locationPanel = ui.Panel({
  widgets: [ui.Label({
    value: 'Sample Locations:', 
    style: {fontWeight: 'bold', fontSize: '12px'}
  })],
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

// Initial visualization
updateVisualization();

print('LANDFIRE Multi-Scale Grid Dashboard loaded successfully!');
print('Use the controls to explore different vegetation datasets with adaptive grids.');