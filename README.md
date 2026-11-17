[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Code and data to reproduce the figures and the scientometric analysis in: "Exploring Copy Number Variation (CNV) in insects: a recommended bioinformatics workflow for CNV identification"

---

## Repository structure
```
.
├── supporting_data/
│   └── RS-final-articles.bib              # Web of Science export (BibTeX) of the 29 articles included in the review
├── scientometric/
│   ├── data/
│   │   └── Most_Frequent_Words_bibliometrix.xlsx   # Curated word frequencies used for the word cloud
│   └── scientometric_analysis.R           # Bibliometric summary (bibliometrix) and word cloud
├── map/
│   ├── data/
│   │   └── data_extraction-map.xlsx       # Order of the studied species and countries of the analysed populations (29 studies)
│   └── countries_map.R                    # World map of the countries sampled in the reviewed studies
├── workflow/
│   └── fig4_workflow.R                    # Fig. 4: CNV identification workflow (two panels)
├── results/                               # Created automatically when the scripts are run
└── README.md
```

## Requirements

- **R** (≥ 4.0.0) — [Download](https://cran.r-project.org/)
- R packages:
  - `scientometric_analysis.R`: bibliometrix (needs rlang ≥ 1.3.0), writexl, readxl, wordcloud, RColorBrewer
  - `countries_map.R`: readxl, dplyr, tidyr, ggplot2, rnaturalearth, rnaturalearthdata, sf, stringr
  - `fig4_workflow.R`: DiagrammeR, DiagrammeRsvg, rsvg, magick

Packages are not installed automatically. If one is missing, the script stops and lists it; install it with `install.packages()` and run the script again.

## How to reproduce the analyses

All paths are relative: run every script with the **project root** (the folder that contains `map/`, `scientometric/`, `supporting_data/` and `workflow/`) as the working directory. In R, use `setwd()` to that folder; in VS Code, open that folder and use the integrated terminal. The three scripts are independent and can be run in any order.

### 1. Scientometric analysis
```r
Rscript scientometric/scientometric_analysis.R
```

Summarises the 29 articles (bibliometrix) and draws the word cloud. Outputs in `results/scientometric/`: bibliometric summary (.txt), data frame (.xlsx), word cloud (.tiff and .jpeg, 600 dpi) and `sessionInfo.txt`.

### 2. Map of sampled countries
```r
Rscript map/countries_map.R
```

Counts the studies per country and draws the choropleth world map. Outputs in `results/map/`: `map_countries.tiff`, `map_countries.jpeg` (600 dpi) and `sessionInfo.txt`.
Country names in the spreadsheet must match the Natural Earth names (e.g. "Dem. Rep. Congo", "Eq. Guinea"). Overseas territories (French Guiana, French Polynesia, Mayotte) are not in that layer and are not drawn; the script lists them when it runs.

### 3. Workflow figure (Fig. 4)
```r
Rscript workflow/fig4_workflow.R
```

Draws the recommended CNV identification route (panel A) and the alternative tools reported in the reviewed studies (panel B). Outputs in `results/fig4/`: one editable SVG per panel and the stacked figure as `Fig4_workflow.png` and `Fig4_workflow.tiff` (600 dpi).

## Data

- `supporting_data/RS-final-articles.bib`: Web of Science export of the articles included in the review.
- `scientometric/data/Most_Frequent_Words_bibliometrix.xlsx`: word frequencies exported from biblioshiny and curated manually. Spelling variants were merged and their frequencies added (the changes are described at the top of `scientometric_analysis.R`).
- `map/data/data_extraction-map.xlsx`: one row per study, with the order of the studied species and the countries of the analysed populations.
- `workflow/fig4_workflow.R`: the number of studies per tool (n) is typed directly in the script, so this figure has no input file.

No additional downloads are required, except the R packages.

## License

This project is licensed under the MIT License.
