"""
This script will plot the MDMR vs GLM summary results.
"""

library(connectir)
library(ggplot2)

# Paths
base <- "/home2/data/Projects/CWAS"
cdir <- file.path(base, "age+gender/04_compare_to_glm/comparison")
dfile <- file.path(cdir, "01_dataframe_glm+mdmr.csv")
odir <- file.path(base, "age+gender/04_compare_to_glm/viz")
dir.create(odir)

# Load the data frame
df <- read.csv(dfile)

# Graph
x11(width=10, height=8)
ggplot(df, aes(mdmr, glm.uwt, color=sample, shape=factor)) + 
    geom_point() + 
    facet_grid(factor ~ sample) + 
    xlab("MDMR Significance (-log10p)") + 
    ylab("GLM Percent Significant Connections")
    
ggsave(file.path(odir, "13-03-07_parcels_mdmr_vs_glm.png"))
dev.off()



