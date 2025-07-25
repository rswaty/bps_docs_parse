// LANDFIRE Simple Dashboard - Basic Version
// This version avoids complex syntax that might cause errors

// Load LANDFIRE data
var evt = ee.ImageCollection("projects/sat-io/open-datasets/landfire/VEGETATION/EVT").first();
var bps = ee.ImageCollection("projects/sat-io/open-datasets/landfire/VEGETATION/BPS").first();
var evc = ee.ImageCollection("projects/sat-io/open-datasets/landfire/VEGETATION/EVC").first();

// Visualization parameters
var evtVis = {min: 0, max: 7000, palette: ['red', 'orange', 'yellow', 'green', 'blue']};
var bpsVis = {min: 0, max: 5000, palette: ['brown', 'orange', 'yellow', 'lightgreen', 'darkgreen']};
var evcVis = {min: 0, max: 100, palette: ['white', 'lightblue', 'blue', 'darkblue', 'navy']};

// Create map
var map = ui.Map();
map.setCenter(-100, 40, 6);

// Title
var title = ui.Label('LANDFIRE Data Viewer', {fontSize: '20px', fontWeight: 'bold'});

// Dataset selector
var datasetSelect = ui.Select({
  items: [
    {label: 'Existing Vegetation Type (EVT)', value: 'EVT'},
    {label: 'Biophysical Settings (BPS)', value: 'BPS'},
    {label: 'Existing Vegetation Cover (EVC)', value: 'EVC'}
  ],
  value: 'EVT'
});

// Update function
function updateMap() {
  var selection = datasetSelect.getValue();
  map.layers().reset();
  
  if (selection === 'EVT') {
    map.addLayer(evt, evtVis, 'Existing Vegetation Type');
  } else if (selection === 'BPS') {
    map.addLayer(bps, bpsVis, 'Biophysical Settings');
  } else if (selection === 'EVC') {
    map.addLayer(evc, evcVis, 'Existing Vegetation Cover');
  }
}

// Event handler
datasetSelect.onChange(updateMap);

// Control panel
var panel = ui.Panel([
  title,
  ui.Label('Select a LANDFIRE dataset:'),
  datasetSelect,
  ui.Label('Instructions:'),
  ui.Label('• Choose dataset from dropdown'),
  ui.Label('• Zoom and pan to explore'),
  ui.Label('• Different colors show different vegetation types')
]);

panel.style().set({
  width: '300px',
  position: 'top-left',
  backgroundColor: 'white',
  padding: '10px'
});

// Sample locations
var locations = [
  {name: 'Yellowstone', lon: -110.5, lat: 44.6, zoom: 10},
  {name: 'California', lon: -121.0, lat: 37.0, zoom: 9},
  {name: 'Florida', lon: -80.9, lat: 25.3, zoom: 10}
];

// Add location buttons
panel.add(ui.Label('Quick locations:', {fontWeight: 'bold'}));
for (var i = 0; i < locations.length; i++) {
  var loc = locations[i];
  var button = ui.Button({
    label: loc.name,
    onClick: (function(location) {
      return function() {
        map.setCenter(location.lon, location.lat, location.zoom);
      };
    })(loc)
  });
  panel.add(button);
}

// Add to map
map.add(panel);

// Initialize
ui.root.clear();
ui.root.add(map);
updateMap();

print('LANDFIRE dashboard loaded successfully!');