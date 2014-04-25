#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(niftir))

base     <- "/home/data/Projects/CWAS"
indir    <- file.path(base, "nki/sca_voxelwise_scan2/30_sca")
maskfile <- file.path(base, "/nki/rois/mask_gray_4mm.nii.gz")
mask     <- read.mask(maskfile)
nvoxs    <- sum(mask)


## Summarizes data.
## Gives count, mean, standard deviation, standard error of the mean, and confidence interval (default 95%).
##   data: a data frame.
##   measurevar: the name of a column that contains the variable to be summariezed
##   groupvars: a vector containing names of columns that contain grouping variables
##   na.rm: a boolean that indicates whether to ignore NA's
##   conf.interval: the percent range of the confidence interval (default is 95%)
summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE,
                      conf.interval=.95, .drop=TRUE) {
    require(plyr)

    # New version of length which can handle NA's: if na.rm==T, don't count them
    length2 <- function (x, na.rm=FALSE) {
        if (na.rm) sum(!is.na(x))
        else       length(x)
    }

    # This is does the summary; it's not easy to understand...
    datac <- ddply(data, groupvars, .drop=.drop,
                   .fun= function(xx, col, na.rm) {
                           c( N    = length2(xx[,col], na.rm=na.rm),
                              mean = mean   (xx[,col], na.rm=na.rm),
                              sd   = sd     (xx[,col], na.rm=na.rm)
                              )
                          },
                    measurevar,
                    na.rm
             )

    # Rename the "mean" column    
    datac <- rename(datac, c("mean"=measurevar))

    datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean

    # Confidence interval multiplier for standard error
    # Calculate t-statistic for confidence interval: 
    # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
    ciMult <- qt(conf.interval/2 + .5, datac$N-1)
    datac$ci <- datac$se * ciMult

    return(datac)
}

        
###
# SETUP
###

# Load the data
df        <- read.csv(file.path(indir, "rois_glm+mdmr.csv"))

# Get a summary with error info
mdf       <- summarySE(df, "sca", c("scan", "label"))

# Relabel
roi_types <- c("maxima", "significant", "not-significant", "minima")
scans     <- c("short", "medium")
mdf$label <- factor(mdf$label, levels=roi_types)
mdf$scan  <- factor(mdf$scan, levels=scans, labels=c("Scan 1", "Scan 2"))

print(mdf)
