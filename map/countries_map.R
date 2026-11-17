# =============================================================================
# World map of the countries sampled in the reviewed studies
# Choropleth map: number of studies (of the 29 reviewed) that sampled each
# country (insect populations).
# Input   : map/data/data_extraction-map.xlsx
# Output  : results/map/
# Note    : overseas territories (French Guiana, French Polynesia, Mayotte) are
#           not in the Natural Earth countries layer and are not drawn; the
#           script lists unmatched names when it runs.
# Packages: readxl, dplyr, tidyr, ggplot2, rnaturalearth, rnaturalearthdata,
#           sf, stringr
# Run from the project root: Rscript map/countries_map.R
# =============================================================================


# ---- 1. Settings -------------------------------------------------------------
# Input file and output folder (relative paths)
input_file <- file.path("map", "data", "data_extraction-map.xlsx")
output_dir <- file.path("results", "map")

# Name of the column with the countries in the spreadsheet
col_country <- "Country of the analysed populations"

# ---- 2. Packages -------------------------------------------------------------

# Packages are NOT installed automatically. If any is missing, install it first:
#   install.packages(c("readxl", "dplyr", "tidyr", "ggplot2", "rnaturalearth",
#                      "rnaturalearthdata", "sf", "stringr"))
# For exact package versions, consider using renv (renv::init(), renv::snapshot()).
required_packages <- c("readxl", "dplyr", "tidyr", "ggplot2", "rnaturalearth",
                       "rnaturalearthdata", "sf", "stringr")
missing_packages <- required_packages[!required_packages %in% rownames(installed.packages())]
if (length(missing_packages) > 0) {
  stop("Missing packages: ", paste(missing_packages, collapse = ", "),
       ". Install them with install.packages() and run the script again.")
}

library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)
library(stringr)


# ---- 3. Input check and output folder ----------------------------------------

if (!file.exists(input_file)) {
  stop("Input file not found: ", input_file,
       "\nCheck that the working directory is the project root (the folder ",
       "that contains 'map') and that the file is in 'map/data'.")
}
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)


# ---- 4. Load the data (29 studies) -------------------------------------------

# "NA" in a cell means that the study did not report a country
study_data <- read_xlsx(input_file, na = c("", "NA"))

if (!col_country %in% names(study_data)) {
  stop("Column not found in the spreadsheet: ", col_country)
}


# ---- 5. Count the studies per country ----------------------------------------

# Counts how many studies sampled each country (one study can list several
# countries separated by commas).
count_countries <- function(data, column) {
  data %>%
    select(country = all_of(column)) %>%
    filter(!is.na(country)) %>%
    separate_rows(country, sep = ",") %>%
    mutate(country = str_trim(country)) %>%
    count(country, name = "frequency")
}

country_counts <- count_countries(study_data, col_country)

# Optional: save the frequency table
# write.csv(country_counts, file.path(output_dir, "country_frequency.csv"),
#           row.names = FALSE)

# Optional: recode names that differ from Natural Earth
if (apply_name_fixes) {
  country_counts <- country_counts %>%
    mutate(country = coalesce(unname(name_fixes[country]), country)) %>%
    group_by(country) %>%
    summarise(frequency = sum(frequency), .groups = "drop")
}


# ---- 6. World map data and join ----------------------------------------------

world <- ne_countries(scale = "medium", returnclass = "sf")

# Report countries of the spreadsheet that are not found in the map layer
unmatched <- setdiff(country_counts$country, world$name)
if (length(unmatched) > 0) {
  not_drawn <- country_counts %>% filter(country %in% unmatched)
  message("Countries NOT drawn on the map (name not found in Natural Earth): ",
          paste0(not_drawn$country, " (", not_drawn$frequency, ")", collapse = "; "),
          ".\nSee 'KNOWN NAME MISMATCHES' in the header of this script.")
}

map_data <- world %>%
  left_join(country_counts, by = c("name" = "country"))


# ---- 7. Draw the map ---------------------------------------------------------

map_figure <- ggplot(data = map_data) +
  geom_sf(aes(fill = frequency), color = "gray", linewidth = 0.1) +
  labs(
    title    = "Countries Sampled in Studies of Insects",
    subtitle = "",
    fill     = "Frequency of studies"
  ) +
  # Blue gradient: light blue = lowest frequency, dark blue = highest
  scale_fill_gradient(
    low      = "lightblue",
    high     = "darkblue",
    na.value = "lightgray"   # countries without data
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title      = element_text(hjust = 0.5),
    plot.subtitle   = element_text(hjust = 0.5)
  )

# Preview on screen
print(map_figure)


# ---- 8. Save the figure (TIFF and JPEG, 600 dpi) -----------------------------

tiff(file.path(output_dir, "map_countries.tiff"),
     width = 8, height = 6, units = "in", res = 600,
     compression = "lzw", type = "cairo")
print(map_figure)
dev.off()

jpeg(file.path(output_dir, "map_countries.jpeg"),
     width = 8, height = 6, units = "in", res = 600,
     quality = 100, type = "cairo")
print(map_figure)
dev.off()

# ---- End of script -----------------------------------------------------------
