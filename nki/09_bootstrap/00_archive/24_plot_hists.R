#' Here I will compare the histograms for the original data against two 
#' bootstrap samples. In all three cases, the data are MDMR results regressing
#' IQ onto functional connectivity maps.
#' 
#' I expect to find that the histogram will have a normal shape for the 
#' original findings but a weird shape for the others.

#+ libraries
suppressPackageStartupMessages(library(niftir))
library(ggplot2)

#+ load
idir <- "/home/data/Projects/CWAS/nki/bootstrap"
load(file.path(idir, "results_short.rda"))

#+ dataframe
df <- data.frame(
  type = rep(c("Original", "Sample 1", "Sample 2"), each=length(results$t0)),   
  vals = c(-log10(results$t0), -log10(results$t[227,]), -log10(results$t[163,]))
)

#+ plot
ggplot(df, aes(x=vals)) + 
  geom_histogram() + 
  facet_grid(type ~ .) + 
  xlab("-log10 p-value") + 
  ylab("Number of Voxels")
