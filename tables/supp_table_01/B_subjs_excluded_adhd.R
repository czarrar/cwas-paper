#!/usr/bin/env Rscript

# 1. Find the QC script and it's output
# 2. Load the output
# 3. Get numbers of subjects excluded at each step
# 4. Confirm that the final count corresponds to the actual # of subjects

ncat <- function(msg, ...) cat(sprintf(msg, ...), "\n")


###
# SETUP/LOAD
###

ncat("Setup")

base        <- "/home2/data/Projects/CWAS"
subdir      <- file.path(base, "share/adhd200_rerun/subinfo")
odir        <- file.path(base, "tables/supp_table_01")

qc.summary  <- read.csv(file.path(subdir, "qc-2_summary.csv"))
qc.values   <- read.csv(file.path(subdir, "qc-2_values.csv"))


# For some reason, 1 subject got dropped along the way...


###
# Number of subjects excluded
###

ncat("Calculating number of subjects excluded")

calc.nexcluded <- function(qc.mat) {
    nuniq <- function(mat) length(unique(mat$subject))
    
    # Get the number of good subjects at each QC step
    good_anat       <- qc.mat
    good_motion     <- subset(good_anat, bad_motion == 0)
    good_cover      <- subset(good_motion, bad_coverage == 0)
    good_snr        <- subset(good_cover, bad_snr == 0)

    # Get the total number of subjects at beginning and end
    nstart          <- nuniq(qc.mat)
    nend            <- nuniq(good_snr)

    # Get the number of subjects excluded at each QC step
    exclude_anat    <- nstart - nuniq(good_anat)
    exclude_motion  <- nuniq(good_anat) - nuniq(good_motion)
    exclude_cover   <- nuniq(good_motion) - nuniq(good_cover)
    exclude_snr     <- nuniq(good_cover) - nuniq(good_snr)
    
    list(nstart=nstart, exclude.anat=exclude_anat, exclude.motion=exclude_anat, 
         exclude.coverage=exclude_cover, exclude.snr=exclude_snr, nend=nend)
}

nums    <- calc.nexcluded(qc.summary)


###
# Save
###

ncat("Save")

con <- file(file.path(odir, "B_subjs_excluded_adhd.txt"))
sink(con, append=TRUE)
print(nums)
sink() 
