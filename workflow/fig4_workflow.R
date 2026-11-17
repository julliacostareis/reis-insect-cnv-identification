# =============================================================================
# Fig. 4 - CNV identification workflow (two panels)
# Panel A: recommended route (dashed = optional steps).
# Panel B: alternative tools reported in the reviewed studies, by workflow step
#          (bold cell = tool of the recommended route; greyed = discontinued).
# n = number of studies (of the 25 Illumina studies out of the 29 reviewed)
# that used each tool; counts are typed directly in this script (from the final
# Supplementary Table S2). Tool versions must match Table 4 of the manuscript.
# Output  : results/fig4/ (SVG per panel; stacked PNG and TIFF, 600 dpi)
# Packages: DiagrammeR, DiagrammeRsvg, rsvg, magick
# Run from the project root: Rscript workflow/fig4_workflow.R
# =============================================================================


# ---- 1. Settings and packages ------------------------------------------------

output_dir <- file.path("results", "fig4")

# Packages are NOT installed automatically. If any is missing, install it first:
#   install.packages(c("DiagrammeR", "DiagrammeRsvg", "rsvg", "magick"))
required_packages <- c("DiagrammeR", "DiagrammeRsvg", "rsvg", "magick")
missing_packages <- required_packages[!required_packages %in% rownames(installed.packages())]
if (length(missing_packages) > 0) {
  stop("Missing packages: ", paste(missing_packages, collapse = ", "),
       ". Install them with install.packages() and run the script again.")
}

library(DiagrammeR)
library(DiagrammeRsvg)
library(rsvg)
library(magick)

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Colour palette of the original figure
col_qc  <- "#DB867E"; bg_qc  <- "#F9EAE8"   # quality control and trimming
col_map <- "#9FDBD8"; bg_map <- "#EAF6F5"   # read mapping and BAM processing
col_cnv <- "#BF90DB"; bg_cnv <- "#F4EBF9"   # CNV identification
col_ini <- "#74DC69"                        # start and end nodes
green   <- "#008000"                        # arrows
grey    <- "#898989"


# ---- 2. Panel A: recommended route -------------------------------------------

# Dashed steps are optional. Tool versions must match Table 4 of the manuscript.
dot_A <- '
digraph A {
  graph [layout = dot, rankdir = TB, nodesep = 0.45, ranksep = 0.42,
         fontname = "Helvetica", label = "A   Recommended route", labelloc = t,
         labeljust = l, fontsize = 22]
  node  [shape = rectangle, style = "filled,rounded", fontname = "Helvetica",
         fontsize = 13, color = black, penwidth = 1.6, width = 4.1, height = 0.62,
         fixedsize = true]
  edge  [color = "#008000", penwidth = 3, arrowsize = 0.8]

  start [label = "Illumina paired-end reads (FASTQ)", fillcolor = "#74DC69",
         fontname = "Helvetica-Bold"]

  subgraph cluster_qc {
    label = ""; style = "filled,rounded"; fillcolor = "#F9EAE8"
    lab1 [label = "1  Quality control\n    and trimming", shape = plaintext, style = "",
          fontname = "Helvetica-Bold", fontsize = 15, width = 2.2, fixedsize = false]
    {rank = same; lab1 -> qc [style = invis]}
    qc   [label = "FastQC (n = 5)\nread quality assessment", fillcolor = "#DB867E"]
    trim [label = "Trimmomatic (n = 4)\nadapter and quality trimming", fillcolor = "#DB867E"]
  }

  subgraph cluster_map {
    label = ""; style = "filled,rounded"; fillcolor = "#EAF6F5"
    lab2 [label = "2  Read mapping and\n    BAM processing", shape = plaintext, style = "",
          fontname = "Helvetica-Bold", fontsize = 15, width = 2.2, fixedsize = false]
    {rank = same; lab2 -> bwa [style = invis]}
    bwa  [label = "BWA / BWA-MEM (n = 11)\nmapping to reference genome", fillcolor = "#9FDBD8"]
    sam  [label = "Samtools (n = 9)\nSAM to BAM, sort, index", fillcolor = "#9FDBD8"]
    dup  [label = "Picard (n = 7)\nPCR duplicate removal", fillcolor = "#9FDBD8"]
  }

  subgraph cluster_cnv {
    label = ""; style = "filled,rounded"; fillcolor = "#F4EBF9"
    lab3 [label = "3  CNV\n    identification", shape = plaintext, style = "",
          fontname = "Helvetica-Bold", fontsize = 15, width = 2.2, fixedsize = false]
    rd1  [label = "CNVnator (n = 4): read-depth histogram\nwindow size chosen from depth", fillcolor = "#BF90DB"]
    rd2  [label = "CNVnator: GC correction\nand mean-shift partitioning", fillcolor = "#BF90DB"]
    rd3  [label = "CNVnator: CNV calling\nfiltering (size, e-value, q0)", fillcolor = "#BF90DB"]
    sv   [label = "DELLY or Manta (n = 2)\nPE/SR breakpoint evidence", fillcolor = "#BF90DB",
          style = "filled,rounded,dashed", width = 2.9]
    mrg  [label = "Integration of RD and PE/SR calls\n(reciprocal overlap)", fillcolor = "#BF90DB",
          style = "filled,rounded,dashed"]
    {rank = same; lab3 -> rd1 -> sv [style = invis]}
  }

  fim  [label = "Candidate CNV set", fillcolor = "#74DC69", fontname = "Helvetica-Bold"]
  dn   [label = "Targeted de novo assembly\nof candidate regions", fillcolor = white,
        style = "rounded,dashed", width = 2.9]
  {rank = same; fim; dn}

  start -> qc -> trim -> bwa -> sam -> dup -> rd1 -> rd2 -> rd3 -> mrg -> fim
  dup -> sv  [style = dashed, penwidth = 2]
  sv  -> mrg [style = dashed, penwidth = 2]
  fim -> dn  [style = dashed, penwidth = 2, color = "#898989", constraint = false]
}
'


# ---- 3. Panel B: catalogue of alternatives (Graphviz HTML table) -------------

# Bold with thick border = tool of the recommended route.
# Greyed out = discontinued procedure.
# n = number of studies (of the 25 Illumina studies that report tools) that used
# the tool. Counts are per study, with standardised tool names
# (e.g. BWA = BWA + BWA-MEM; Picard = all its variants).
n_studies <- 25

# One table cell: tool name and its count
make_cell <- function(txt, n, color, recommended = FALSE, obsolete = FALSE) {
  border_width <- if (recommended) 3 else 1
  txt <- paste0(txt, "<BR/><FONT POINT-SIZE=\"11\">n = ", n, "</FONT>")
  if (recommended) txt <- paste0("<B>", txt, "</B>")
  if (obsolete) {
    color <- "#E6E6E6"
    txt <- paste0("<FONT COLOR=\"#777777\">", txt, "</FONT>")
  }
  sprintf('<TD BGCOLOR="%s" BORDER="%d" STYLE="rounded" CELLPADDING="6">%s</TD>',
          color, border_width, txt)
}

# One workflow step: up to 4 tools per row; steps with more tools continue on
# the next row
make_row <- function(stage, bg_color, cells, n_col = 4) {
  blocks <- split(cells, ceiling(seq_along(cells) / n_col))
  out <- character(0)
  for (i in seq_along(blocks)) {
    cel <- blocks[[i]]
    padding <- if (length(cel) < n_col) {
      paste(rep('<TD BORDER="0"></TD>', n_col - length(cel)), collapse = "")
    } else {
      ""
    }
    stage_label <- if (i == 1) paste0("<B>", stage, "</B>") else ""
    out <- c(out, sprintf('<TR><TD ALIGN="LEFT" BGCOLOR="%s" BORDER="0" CELLPADDING="8">%s</TD>%s%s</TR>',
                          bg_color, stage_label, paste(unlist(cel), collapse = ""), padding))
  }
  paste(out, collapse = "\n")
}

rows_B <- c(
  make_row("Quality assessment", bg_qc,  list(make_cell("FastQC", 5, col_qc, TRUE))),
  make_row("Trimming",           bg_qc,  list(make_cell("Trimmomatic", 4, col_qc, TRUE),
                                              make_cell("Cutadapt", 1, col_qc),
                                              make_cell("AdapterRemoval", 1, col_qc),
                                              make_cell("Sickle", 1, col_qc),
                                              make_cell("FASTX-Toolkit", 1, col_qc))),
  make_row("Read mapping",       bg_map, list(make_cell("BWA / BWA-MEM", 11, col_map, TRUE),
                                              make_cell("Bowtie2", 3, col_map),
                                              make_cell("Stampy", 2, col_map),
                                              make_cell("Minimap2", 1, col_map))),
  make_row("BAM processing",     bg_map, list(make_cell("Samtools", 9, col_map, TRUE),
                                              make_cell("Bedtools", 3, col_map),
                                              make_cell("Bcftools", 2, col_map),
                                              make_cell("Qualimap (coverage QC)", 1, col_map),
                                              make_cell("GeneSpring NGS (filtering)", 1, col_map),
                                              make_cell("GATK3 indel realignment<BR/>(removed in GATK4)", 3, col_map, obsolete = TRUE))),
  make_row("Duplicate removal",  bg_map, list(make_cell("Picard", 7, col_map, TRUE),
                                              make_cell("FastUniq", 1, col_map))),
  make_row("Read depth (RD)",    bg_cnv, list(make_cell("CNVnator", 4, col_cnv, TRUE),
                                              make_cell("Gaussian HMM<BR/>(Ag1000G pipeline)", 4, col_cnv),
                                              make_cell("CNVcaller", 1, col_cnv),
                                              make_cell("readDepth + CNAnorm", 1, col_cnv),
                                              make_cell("optimalCaptureSegmentation (R)", 1, col_cnv),
                                              make_cell("Samtools depth / Bedtools", 2, col_cnv))),
  make_row("Paired-end / split-read", bg_cnv, list(make_cell("DELLY (PE + SR)", 2, col_cnv),
                                              make_cell("Pindel (SR)", 2, col_cnv),
                                              make_cell("Manta (PE + SR)", 1, col_cnv),
                                              make_cell("BreakDancer (PE)", 1, col_cnv))),
  make_row("Combining signals",  bg_cnv, list(make_cell("poolCNVcomp (RD + PE)", 1, col_cnv),
                                              make_cell("SURVIVOR (call merging)", 1, col_cnv),
                                              make_cell("intansv (call merging)", 1, col_cnv))),
  make_row("Custom code",        bg_cnv, list(make_cell("Custom scripts (R, Perl, Python)", 13, col_cnv))),
  make_row("De novo assembly",   bg_cnv, list(make_cell("PrInSeS-G (local assembly)", 1, col_cnv),
                                              make_cell("ALLPathsLG + Platanus,<BR/>REPET, LASTZ/chainNet", 1, col_cnv))),
  make_row("Integrated platforms", "#EFEFEF", list(make_cell("CLC Genomics Workbench", 1, "#D9D9D9"),
                                              make_cell("Strand NGS", 1, "#D9D9D9")))
)

dot_B <- paste0('
digraph B {
  graph [fontname = "Helvetica", label = "B   Alternatives reported in the reviewed studies",
         labelloc = t, labeljust = l, fontsize = 22]
  node  [shape = plaintext, fontname = "Helvetica", fontsize = 13]
  tab [label = <<TABLE BORDER="0" CELLSPACING="5">',
  paste(rows_B, collapse = "\n"),
  '</TABLE>>]
}
')


# ---- 4. Export: editable SVG per panel + combined PNG/TIFF -------------------

svg_A <- export_svg(grViz(dot_A))
svg_B <- export_svg(grViz(dot_B))

# Helvetica does not exist on Windows and the substitute font, which is wider,
# clips the labels. Arial has the same metrics that Graphviz uses for the layout.
svg_A <- gsub("Helvetica,sans-Serif", "Arial,Helvetica,sans-Serif", svg_A, fixed = TRUE)
svg_B <- gsub("Helvetica,sans-Serif", "Arial,Helvetica,sans-Serif", svg_B, fixed = TRUE)

svg_A_file <- file.path(output_dir, "Fig4A_recommended_route.svg")
svg_B_file <- file.path(output_dir, "Fig4B_alternatives.svg")
writeLines(svg_A, svg_A_file)
writeLines(svg_B, svg_B_file)

# Stacked panels (A on top, B below), same width
width_px <- 3000
img_A <- image_read_svg(svg_A_file, width = width_px)
img_B <- image_read_svg(svg_B_file, width = width_px)

fig <- image_append(c(img_A, image_blank(width_px, 120, "white"), img_B), stack = TRUE)
fig <- image_background(fig, "white")
image_write(fig, file.path(output_dir, "Fig4_workflow.png"),
            format = "png", density = 600)
image_write(fig, file.path(output_dir, "Fig4_workflow.tiff"),
            format = "tiff", density = 600, compression = "LZW")

# ---- End of script -----------------------------------------------------------
