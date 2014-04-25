
scan <- "short"

idir  <- "/home/data/Projects/CWAS/nki/bootstrap"
rfile <- file.path(idir, sprintf("results_%s.rda", scan))

# should have results and prop_sig
load(rfile)

# We have all the bootstrap CWAS maps
# let's get the correlation between them
results$t

