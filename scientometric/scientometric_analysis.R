# =============================================================================
# Scientometric analysis of the reviewed articles
# Bibliometric summary (bibliometrix) and word cloud of the 29 articles
# selected from Web of Science.
# Input   : supporting_data/RS-final-articles.bib (Web of Science, BibTeX)
#           scientometric/data/Most_Frequent_Words_bibliometrix.xlsx
#           (curated word frequencies, see below)
# Output  : results/scientometric/ (summary, data frame, word cloud TIFF/JPEG,
#           sessionInfo.txt)
# Curation: the word table comes from biblioshiny (Words > Most Frequent Words).
#           Spelling variants were merged and their frequencies added:
#           aedes aegypti (3+2 = 5); copy number variation (6+3+2 = 11);
#           gene (3+3 = 6); population (3+3 = 6). 50 terms became 45; the
#           total frequency is unchanged (156).
# Packages: bibliometrix (needs rlang >= 1.3.0), writexl, readxl, wordcloud,
#           RColorBrewer
# Run from the project root: Rscript scientometric/scientometric_analysis.R
# =============================================================================


# ---- 1. Settings -------------------------------------------------------------

# Input files and output folder (relative paths)
wos_file    <- file.path("supporting_data", "RS-final-articles.bib")
words_file  <- file.path("scientometric", "data", "Most_Frequent_Words_bibliometrix.xlsx")
output_dir  <- file.path("results", "scientometric")

# Reproducibility: same word layout every time the cloud is drawn
cloud_seed <- 123


# ---- 2. Packages -------------------------------------------------------------

# Packages are NOT installed automatically. If any is missing, install it first:
#   install.packages(c("bibliometrix", "writexl", "readxl", "wordcloud",
#                      "RColorBrewer"))
# For exact package versions, consider using renv (renv::init(), renv::snapshot()).
required_packages <- c("rlang", "bibliometrix", "writexl", "readxl",
                       "wordcloud", "RColorBrewer")
missing_packages <- required_packages[!required_packages %in% rownames(installed.packages())]
if (length(missing_packages) > 0) {
  stop("Missing packages: ", paste(missing_packages, collapse = ", "),
       ". Install them with install.packages() and run the script again.")
}

# bibliometrix needs rlang >= 1.3.0 (packageVersion compares versions correctly)
if (packageVersion("rlang") < "1.3.0") {
  stop("rlang is older than 1.3.0. Update it with install.packages('rlang'), ",
       "restart R (Session > Restart R) and run the script again.")
}

library(bibliometrix)
library(writexl)
library(readxl)
library(wordcloud)
library(RColorBrewer)


# ---- 3. Input check and output folder ----------------------------------------

for (f in c(wos_file, words_file)) {
  if (!file.exists(f)) {
    stop("Input file not found: ", f,
         "\nCheck that the working directory is the project root (the folder ",
         "that contains 'scientometric' and 'supporting_data') and that the ",
         "file is in the expected folder (see section 1).")
  }
}
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)


# ---- 4. Bibliometric analysis ------------------------------------------------

# Import the .bib file and convert it to a bibliometric data frame
bib_data <- convert2df(file = wos_file, dbsource = "wos", format = "bibtex")

# biblioAnalysis() computes the main bibliometric metrics
analysis_results <- biblioAnalysis(bib_data)

# Summary: number of documents, authors, keywords, etc.
summary(analysis_results)

# Save the summary as a text file
capture.output(summary(analysis_results),
               file = file.path(output_dir, "bibliometric_summary.txt"))

# Save the data frame for later use
write_xlsx(bib_data, file.path(output_dir, "bibliometric_data.xlsx"))


# ---- 5. Word cloud -----------------------------------------------------------

# Curated word-frequency table (see "CURATION OF THE WORD-FREQUENCY TABLE" in the
# header). skip = 1 skips the extra first line present in the biblioshiny export.
word_table <- read_xlsx(words_file, skip = 1)
if (!all(c("Terms", "Frequency") %in% names(word_table))) {
  stop("Unexpected columns in ", words_file,
       ". Expected 'Terms' and 'Frequency'.")
}

cloud_colors <- brewer.pal(8, "Dark2")

draw_cloud <- function() {
  set.seed(cloud_seed)
  par(mar = c(0, 0, 0, 0))
  wordcloud(
    words        = word_table$Terms,
    freq         = word_table$Frequency,
    min.freq     = 2,
    max.words    = 100,
    random.order = FALSE,
    colors       = cloud_colors,
    rot.per      = 0,
    scale        = c(3, 0.5),
    font         = 2
  )
}

# Preview on screen
draw_cloud()

# Save the figure as TIFF (600 dpi, LZW) and JPEG (600 dpi)
tiff(file.path(output_dir, "word_cloud.tiff"),
     width = 5, height = 5, units = "in", res = 600,
     compression = "lzw", type = "cairo")
draw_cloud()
dev.off()

jpeg(file.path(output_dir, "word_cloud.jpeg"),
     width = 5, height = 5, units = "in", res = 600,
     quality = 100, type = "cairo")
draw_cloud()
dev.off()


# ---- 6. Session information (reproducibility) --------------------------------

writeLines(capture.output(sessionInfo()),
           file.path(output_dir, "sessionInfo.txt"))


# ---- 7. Biblioshiny (interactive only) ---------------------------------------

# Kept last: R waits until biblioshiny is closed. Only opens in interactive
# sessions, so the script can also be run in batch mode (Rscript) without hanging.
# The original word-frequency table was exported from here
# (Words > Most Frequent Words > export to Excel) before the curation above.
if (interactive()) {
  biblioshiny()
}

# ---- End of script -----------------------------------------------------------
