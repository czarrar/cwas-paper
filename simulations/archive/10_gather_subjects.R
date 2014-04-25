#!/usr/bin/env Rscript

#' # Overview
#' 
#' For these, simulations we have decided to make use of real data. We will 
#' take the residuals from real resting-state data and then add varying amounts
#' of group differences to simulate group effects. The data I will be using will
#' be from 5 different sites (found on FCON1000 and INDI) including
#'
#'     * Beijing
#'     * Cambridge
#'     * Rockland
#'     * NYU (A...not sure what that means)
#'     * Berlin
#' 
#' These subjects were already preprocessing and what not in the age+gender 
#' folder. So my job here will be to compile info from the other folder.


#' # Setup
#+ setup

# Needed libraries
library(plyr)

# Base Paths
basedir     <- "/home/data/Projects/CWAS"
sdir        <- file.path(basedir, "share/age+gender/subinfo")

# Subject info and paths
df          <- read.csv(file.path(sdir, "04_all_df.csv"))


#' # Filter
#' We will only be looking at subject data for the desired sites.
#+ filter
sites.to_use    <- c("Beijing A", "Cambridge", "Rockland", "New York A", "Berlin")
filt.df         <- subset(df, site %in% sites.to_use)
roipaths        <- file.path(filt.df$outdir, "func/bandpass_freqs_0.01.0.1/rois_random_k0400.nii.gz")

if (!all(file.exists(roipaths))) stop("not all roipaths exist")

#can't use compcor since didn't extract ts for it
#strat0   <- "linear1.wm1.motion1.csf1_CSF_0.98_GM_0.7_WM_0.98"
#strat1   <- "_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98"
#roipaths <- sub(strat0, strat1, roipaths)


#' # Summary
#' Let's see the Ns for each site
#+ site-ns
ddply(filt.df, .(site), nrow)
#         site  V1
# 1  Beijing A 188
# 2     Berlin  74
# 3  Cambridge 184
# 4 New York A  78
# 5   Rockland 132

#' # Save
#+ save
write.csv(filt.df, file="subinfo/10_subject_info.csv")
write.table(roipaths, row.names=F, col.names=F, file="subinfo/12_rois0400_paths.txt")


# TODO
# 1. Read in subject data
# 2. Compute connectivity for all possible connections
#    a. then vary selection of sample size
# 3. Add in the group effect randomly
#    a. only positive or half pos / half neg group differences
#    b. select N nodes and vary number of connections with that node with group difference
#    c. vary group difference (effect size) that added
# 4. Determine the mean global connectivity
# 5. Regress out the main effects including or not including the mean global connectivity
# 6. Run ANOVA, global, and MDMR
