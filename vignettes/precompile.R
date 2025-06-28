# Precompute vignettes that require API access
# Following rOpenSci guide: https://ropensci.org/blog/2019/12/08/precompute-vignettes/

library(knitr)

# Set figure path for better figure management
knitr::opts_chunk$set(fig.path = "cnbrrr_files/figure-html/")

# Knit the original vignette to create the precomputed version
knitr::knit("vignettes/cnbrrr.Rmd.orig", output = "vignettes/cnbrrr.Rmd")

cat("Precomputed vignette created!\n")
cat("- Original source: cnbrrr.Rmd.orig\n")
cat("- Precomputed version: cnbrrr.Rmd\n")
cat("- Figures saved in: cnbrrr_files/\n")
cat("\nIMPORTANT: Re-run this script when the package changes significantly.\n")
