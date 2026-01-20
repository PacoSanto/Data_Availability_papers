# Data Directory Documentation

This directory contains input data, example outputs, and documentation for the MCDA-Lunar-ISRU workflow.

---

## Directory Structure

```
data/
├── input/              # User-provided input files (5 TXT files required)
├── example_outputs/    # Example results from Carpatus Mons case study
└── README_data.md      # This file
```

---

## Input Data Requirements

### **Required Files (5 total)**

All input files must be placed in `data/input/` with these exact names:

1. **FeO.txt** - Iron oxide abundance (wt%)
2. **TiO2.txt** - Titanium oxide abundance (wt%)
3. **Glass.txt** - Volcanic glass index (dimensionless)
4. **OMAT.txt** - Optical maturity index (0-1 scale)
5. **OH.txt** - Hydroxyl/water absorption depth

---

### **File Format Specifications**

Each TXT file must follow this structure:

```
Value   X       Y
12.45   -15.234 23.456
8.32    -15.233 23.457
15.67   -15.232 23.458
...
```

**Column descriptions:**
- **Value**: Measured parameter value (float)
- **X**: Longitude in decimal degrees (float)
- **Y**: Latitude in decimal degrees (float)

**Delimiter**: Tab (`\t`) or space

**Header**: First line must be exactly `Value X Y` (or similar - will be skipped)

---

### **Critical Requirements**

 **Spatial alignment**: All 5 files MUST have:
   - Same number of rows (pixels)
   - Identical X, Y coordinates for each row
   - Same spatial extent and resolution

 **NoData handling**: Invalid values should be:
   - `< -1e30` (e.g., -3.4028e+38 for GIS NoData)
   - Script will automatically mask these values

 **Coordinate system**: Planetocentric latitude/longitude (degrees)

 **Value ranges** (typical for lunar data):
   - FeO: 5-25 wt%
   - TiO2: 0-15 wt%
   - Glass: Dimensionless index (varies by calculation method)
   - OMAT: 0-1 (0 = immature, 1 = very mature)
   - OH: 0-0.1 (absorption band depth)

---

## Data Sources & References

### **Global Compositional Maps**
- **FeO & TiO2**: Zhang, L., et al. (2023). Global FeO and TiO₂ abundance maps. *Icarus*.
  - Available at: [NASA PDS Geosciences Node]
  
- **OMAT**: Lemelin, M., et al. (2016). Global map of lunar crustal composition. *Planetary and Space Science*.
  - Available at: [NASA PDS]

- **OH/H2O**: Pieters, C.M., et al. (2009). Character and spatial distribution of OH/H₂O. *Science*.
  - Derived from M³ Level 2 data
  - Available at: [ISRO Science Data Archive]

### **Spectral Data (for Glass Index)**
- **M³ (Moon Mineralogy Mapper)**: Chandrayaan-1, ISRO
  - Spatial resolution: 110 m/pixel
  - Spectral range: 430-3000 nm (85 bands)
  - Download: [PDS Imaging Node]
