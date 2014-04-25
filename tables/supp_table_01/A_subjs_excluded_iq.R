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
subdir      <- file.path(base, "share/nki/subinfo")
odir        <- file.path(base, "tables/supp_table_01")

qc.scan1    <- read.csv(file.path(subdir, "qc-4_summary_short.csv"))
qc.scan2    <- read.csv(file.path(subdir, "qc-4_summary_medium.csv"))
qc.combined <- read.csv(file.path(subdir, "qc-2_usable_scans.csv"))

# For some reason, 1 subject got dropped along the way...


###
# Number of subjects excluded
###

ncat("Calculating number of subjects excluded")

calc.nexcluded <- function(qc.mat) {
    # Get the number of good subjects at each QC step
    good_anat       <- subset(qc.mat, bad_anat == 0)
    good_motion     <- subset(good_anat, bad_motion == 0)
    good_cover      <- subset(good_motion, bad_coverage == 0)
    good_snr        <- subset(good_cover, bad_snr == 0)

    # Get the total number of subjects at beginning and end
    nstart          <- nrow(qc.mat)
    nend            <- nrow(good_snr)

    # Get the number of subjects excluded at each QC step
    exclude_anat    <- nstart - nrow(good_anat)
    exclude_motion  <- nrow(good_anat) - nrow(good_motion)
    exclude_cover   <- nrow(good_motion) - nrow(good_cover)
    exclude_snr     <- nrow(good_cover) - nrow(good_snr)
    
    list(nstart=nstart, exclude.anat=exclude_anat, exclude.motion=exclude_anat, 
         exclude.coverage=exclude_cover, exclude.snr=exclude_snr, nend=nend)
}

nums.scan1  <- calc.nexcluded(qc.scan1)
nums.scan2  <- calc.nexcluded(qc.scan2)

qc.filt     <- qc.combined[qc.combined$short==1 & qc.combined$medium==1,]
nums.combined <- list(
    ncombined = nrow(qc.filt), 
    nage      = sum(qc.filt$Age>=18 & qc.filt$Age<=65)
)
# for some reason, there is one extra subject


###
# Save
###

ncat("Save")

con <- file(file.path(odir, "A_subjs_excluded_iq.txt"))
sink(con, append=TRUE)

ncat("Scan 1")
print(nums.scan1)

ncat("Scan 2")
print(nums.scan2)

ncat("Combined")
print(nums.combined)

sink() 
