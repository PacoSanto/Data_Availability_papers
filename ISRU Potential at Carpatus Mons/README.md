# MCDA-Lunar-ISRU

**Multi-Criteria Decision Analysis for Lunar In-Situ Resource Utilization (ISRU) Site Selection**

[![MATLAB](https://img.shields.io/badge/MATLAB-R2020a+-orange.svg)](https://www.mathworks.com/products/matlab.html)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Overview

This repository contains a quantitative **Multi-Criteria Decision Analysis (MCDA)** framework for evaluating In-Situ Resource Utilization (ISRU) potential in lunar pyroclastic deposits. The methodology integrates compositional, spectral, and environmental parameters from orbital remote sensing data to identify optimal sites for:

- **Oxygen extraction** from ilmenite and volcanic glass
- **Volatile harvesting** from solar wind-implanted regolith

The framework was developed and applied to the **Carpatus Mons Dark Mantle Deposit (DMD)** but is designed to be **generalizable to other lunar pyroclastic deposits**.

---

## Key Features

**Weighted Linear Combination (WLC)** approach for objective site ranking 
**Literature-based weight assignments** reflecting ISRU mission priorities 
**Handles NoData values** and spatial misalignment
**Generates normalized suitability scores** (0-10 scale) for:
   - Oxygen extraction potential (S_O₂)
   - Volatile extraction potential (S_volatiles)
   - Combined ISRU suitability (S_combined)

**Automated report generation** with statistics and top-ranked sites
**Visualization tools** for spatial score distributions

---

## Methodology

The MCDA framework evaluates two assessment domains:

### 1. **Oxygen Extraction Score (S_O₂)**
Focuses on compositional parameters that determine oxygen yield:

```
S_O₂ = 0.69 · f(TiO₂, FeO) + 0.31 · f(Glass)
```

**Parameters:**
- **TiO₂ + FeO**: Oxide content for ilmenite reduction
- **Glass**: Amorphous material for hydrogen reduction

**Weight rationale**: Oxides receive higher priority (0.69) as they directly determine oxygen production efficiency in lunar reduction processes.

---

### 2. **Volatile Extraction Score (S_volatiles)**
Evaluates solar wind implantation potential and indigenous water/OH:

```
S_volatiles = 0.45 · f(Glass) + 0.35 · f(OMAT) + 0.10 · f(OH) + 0.10 · f(FeO)
```

**Parameters:**
- **Glass**: High surface area for volatile implantation
- **OMAT (Optical Maturity)**: Proxy for regolith exposure age
- **OH**: Hydroxyl/water signature from 3 μm absorption
- **FeO**: Nanophase Fe⁰ indicator (catalyzes H₂ retention)

**Weight rationale**: Glass and OMAT dominate (0.80 combined) as they control solar wind volatile accumulation over geological timescales.

---

## Input Data Requirements

The workflow requires **5 input TXT files** with identical spatial grids:

| Parameter | Description | Source | Units |
|-----------|-------------|--------|-------|
| `FeO.txt` | Iron oxide abundance | Global FeO mosaic (e.g., Zhang et al., 2023) | wt% |
| `TiO2.txt` | Titanium oxide abundance | Global TiO₂ mosaic | wt% |
| `Glass.txt` | Volcanic glass index | Derived from M³ spectral parameters | Dimensionless |
| `OMAT.txt` | Optical maturity | OMAT global map (e.g. Lemelin et al., 2016) | Dimensionless (0-1) |
| `OH.txt` | Hydroxyl signature | M³ 3 μm band depth | Absorption depth |

### **File Format**
Each TXT file must have 3 tab-separated columns with header:

```
Value   X       Y
12.5    -15.234 23.456
8.3     -15.233 23.457
...
```

- `Value`: Parameter measurement
- `X`: Longitude (decimal degrees)
- `Y`: Latitude (decimal degrees)

**Note**: All files must have:
- Identical number of rows (pixels)
- Identical X, Y coordinates (aligned grids)
- NoData values < -1e30 (automatically masked)

---

## Installation & Usage

### **Requirements**
- MATLAB R2020a or later
- No additional toolboxes required

### **Quick Start**

1. **Prepare input data:**
   - Place your 5 TXT files in `data/input/`
   - Ensure files follow the required format (see above)

2. **Configure paths in MATLAB script:**
   Edit `src/MCDA_ISRU_analysis.m`:
   ```matlab
   input_folder = 'data/input/';  % Path to your input TXT files
   output_folder = 'data/output/'; % Where to save results
   ```

3. **Run the analysis:**
   ```matlab
   cd src/
   MCDA_ISRU_analysis
   ```

4. **Check outputs** in `data/output/`:
   - `S_O2_score.txt` - Oxygen extraction suitability
   - `S_volatiles_score.txt` - Volatile extraction suitability
   - `S_combined_score.txt` - Combined ISRU suitability
   - `MCDA_Analysis_Report.txt` - Summary statistics
   - Visualization PNGs/FIGs

---

## Output Files

The workflow generates the following outputs:

### **Suitability Score Maps (TXT format)**
| File | Description | Scale |
|------|-------------|-------|
| `S_O2_score.txt` | Oxygen extraction potential | 0-10 |
| `S_volatiles_score.txt` | Volatile extraction potential | 0-10 |
| `S_combined_score.txt` | Combined ISRU suitability (50% O₂ + 50% volatiles) | 0-10 |

### **Normalized Parameter Functions**
- `f_oxides_norm.txt` - Combined TiO₂+FeO function
- `f_glass_norm.txt` - Glass abundance (min-max normalized)
- `f_OMAT_norm.txt` - Optical maturity (min-max normalized)
- `f_OH_norm.txt` - Hydroxyl signature (min-max normalized)
- `f_Fe_norm.txt` - FeO for volatiles (min-max normalized)

### **Visualizations**
- `MCDA_Visualization.png` - Score maps (0-10 fixed scale)
- `MCDA_Visualization_AutoScale.png` - Score maps (auto-scaled to data range)

---

## Case Study: Carpatus Mons DMD

This framework was applied to a ~940 km² dark mantle deposit near Carpatus Mons, revealing:

- **Optimal ISRU zone**: Central-eastern sector with scores >8.0
- **Key finding**: Proximity to pyroclastic source vents correlates with highest resource potential
- **Best sites**: ~85 km² with combined scores 8.5-9.2 identified for mission planning

Results are in review.

---

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## Contact

For questions or collaborations:

- **Author**: [Francesco Santoro De Vico] - [francesco.santoro@unipd.it]

---

## Acknowledgments

This research utilized data from:
- NASA Lunar Reconnaissance Orbiter (LRO)
- ISRO Chandrayaan-1 Moon Mineralogy Mapper (M³)
- Global compositional mosaics (Zhang et al., 2023; Lemelin et al., 2016)

---

## References

- Chambers, J.G., et al. (1995). Beneficiation of lunar ilmenite. *Resources of Near-Earth Space*.
- Gibson, M.A., Knudsen, C.W. (1985). Lunar oxygen production from ilmenite. *AIAA Space Programs and Technologies Conference*.
- Lemelin, M., et al. (2016). Global map of lunar crustal composition. *Planetary and Space Science*.
- Lucey, P.G., et al. (2000). Lunar iron and titanium abundance algorithms. *Journal of Geophysical Research*.
- Malczewski, J. (2006). GIS-based multicriteria decision analysis. *International Journal of Geographical Information Science*.
- Pieters, C.M., et al. (2009). Character and spatial distribution of OH/H₂O on the Moon. *Science*.
- Zhang, L., et al. (2023). Global FeO and TiO₂ abundance maps of the Moon. *Icarus*.
