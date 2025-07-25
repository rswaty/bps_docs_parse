# LANDFIRE Multi-Scale Hexagonal Dashboard - Deployment Guide

## Overview
This guide will help you deploy the LANDFIRE hexagonal visualization dashboard as a shareable Google Earth Engine App that users can access through a web browser.

## Features
- **Multi-scale hexagonal grids**: Automatically adjusts H3 resolution based on zoom level
- **7 LANDFIRE datasets**: BPS, EVC, EVH, EVT, SCLASS, VCC, VDEP
- **Interactive controls**: Dataset selector, zoom-responsive hexagons, sample locations
- **Real-time aggregation**: Calculates majority values from rasters to hexagons
- **Professional UI**: Legends, instructions, and responsive design

## Step-by-Step Deployment

### 1. Set Up Google Earth Engine Account
1. Go to [Google Earth Engine](https://earthengine.google.com/)
2. Sign up/log in with your Google account
3. Complete the Earth Engine registration process
4. Access the [Code Editor](https://code.earthengine.google.com/)

### 2. Create the App Script
1. Open the GEE Code Editor
2. Create a new script
3. Copy and paste the entire content from `landfire_hexagon_dashboard.js`
4. Save the script with a descriptive name like "LANDFIRE_Hexagonal_Dashboard"

### 3. Test the Dashboard
1. Click "Run" in the Code Editor
2. Wait for the app to load (may take 30-60 seconds)
3. Test the following features:
   - Dataset dropdown selection
   - Zoom in/out to see hexagon resolution changes
   - Pan to different locations
   - Use sample location buttons
   - Verify legend updates

### 4. Deploy as Public App

#### Option A: Google Earth Engine Apps (Recommended)
1. In the Code Editor, click "Apps" in the top menu
2. Click "New App"
3. Fill out the form:
   - **App Name**: "LANDFIRE Hexagonal Dashboard"
   - **Description**: "Interactive multi-scale hexagonal visualization of LANDFIRE vegetation data"
   - **Source Script**: Select your dashboard script
   - **Visibility**: Choose "Public" for sharing
4. Click "Create App"
5. Wait for deployment (can take several minutes)
6. You'll get a shareable URL like: `https://yourapp.earthengine.app/view/landfire-dashboard`

#### Option B: GitHub Pages Integration
1. Create a GitHub repository
2. Add the script as `main.js`
3. Create an `index.html` file:

```html
<!DOCTYPE html>
<html>
<head>
    <title>LANDFIRE Hexagonal Dashboard</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <script src="https://earthengine.googleapis.com/v1/earthengine_api.js"></script>
    <script src="main.js"></script>
</body>
</html>
```

### 5. Share Your Dashboard

#### Shareable Link Options:
1. **Direct GEE App URL**: `https://yourapp.earthengine.app/view/your-app-name`
2. **Embed in website**: Use iframe embedding
3. **Social sharing**: Share URL directly

#### Embedding Code:
```html
<iframe 
    src="https://yourapp.earthengine.app/view/your-app-name" 
    width="100%" 
    height="600px" 
    frameborder="0">
</iframe>
```

## Customization Options

### Adding New Datasets
```javascript
// Add to the visParams object
var visParams = {
  'YOUR_DATASET': {
    min: 0, 
    max: 100, 
    palette: ['#color1', '#color2', '#color3']
  }
};

// Add to dataset selector
var datasetSelect = ui.Select({
  items: ['BPS', 'EVC', 'EVH', 'EVT', 'SCLASS', 'VCC', 'VDEP', 'YOUR_DATASET'],
  // ...
});
```

### Modifying H3 Resolution Mapping
```javascript
function getH3ResolutionFromZoom(zoomLevel) {
  if (zoomLevel <= 4) return 2;  // Very large hexagons
  if (zoomLevel <= 6) return 3;  // Large hexagons
  if (zoomLevel <= 8) return 4;  // Medium-large hexagons
  if (zoomLevel <= 10) return 5; // Medium hexagons
  if (zoomLevel <= 12) return 6; // Small hexagons
  if (zoomLevel <= 14) return 7; // Very small hexagons
  return 8; // Finest resolution
}
```

### Adding Custom Study Areas
```javascript
var customLocations = [
  {name: 'Your Study Area', coords: [-120.0, 45.0], zoom: 12},
  {name: 'Another Location', coords: [-110.0, 40.0], zoom: 10}
];
```

## Performance Optimization

### For Large Areas:
1. **Limit H3 resolution**: Cap maximum resolution at 7 instead of 8
2. **Add loading indicators**: Implement progress bars
3. **Cache results**: Store computed hexagons temporarily

### Code Optimization:
```javascript
// Add loading indicator
var loadingLabel = ui.Label('Loading...', {color: 'blue'});

function updateVisualization() {
  controlPanel.add(loadingLabel);
  
  // Your existing code...
  
  controlPanel.remove(loadingLabel);
}
```

## Troubleshooting

### Common Issues:

1. **"User memory limit exceeded"**
   - Reduce H3 resolution maximum
   - Implement area-based resolution limits

2. **"Computation timeout"**
   - Add `maxPixels` parameter to reduceRegion
   - Use `bestEffort: true` in reduce operations

3. **Slow loading**
   - Implement debounced updates
   - Cache hexagon grids for repeated views

### Debug Mode:
```javascript
// Add debug printing
function updateVisualization() {
  print('Current zoom:', map.getZoom());
  print('H3 resolution:', h3Resolution);
  print('Number of hexagons:', hexagons.size());
}
```

## User Guide for End Users

### How to Use the Dashboard:
1. **Select Dataset**: Use dropdown to choose LANDFIRE dataset
2. **Navigate**: 
   - Zoom in/out to see different hexagon resolutions
   - Pan to explore different geographic areas
   - Use sample location buttons for quick navigation
3. **Interpret**: 
   - Colors represent majority values within each hexagon
   - Legend shows value ranges
   - Smaller hexagons (higher zoom) = more detail

### Best Practices for Users:
- Start at zoom level 6-8 for overview
- Zoom to 10-12 for detailed analysis
- Use sample locations to see different ecosystems
- Compare original raster with hexagonal aggregation

## Maintenance and Updates

### Regular Maintenance:
1. **Check LANDFIRE data updates**: New versions are released periodically
2. **Monitor app performance**: Watch for user feedback
3. **Update color schemes**: Adjust based on user needs

### Version Control:
```javascript
// Add version info to your script
var VERSION = '1.0.0';
var LAST_UPDATED = '2024-01-15';

print('Dashboard Version:', VERSION);
print('Last Updated:', LAST_UPDATED);
```

## Support and Documentation

### For Users:
- Include contact information in the app
- Provide link to LANDFIRE documentation
- Add tooltips for interactive elements

### For Developers:
- Document code changes
- Maintain changelog
- Test before deploying updates

## Success Metrics

Track these metrics to measure dashboard success:
- Number of unique users
- Session duration
- Most popular datasets
- Geographic areas of interest
- User feedback and feature requests

---

## Ready to Deploy?

1. ✅ Copy the dashboard code
2. ✅ Test in GEE Code Editor
3. ✅ Deploy as GEE App
4. ✅ Share the URL
5. ✅ Gather user feedback
6. ✅ Iterate and improve

Your LANDFIRE hexagonal dashboard will provide users with an intuitive, fast way to explore vegetation data at multiple scales!