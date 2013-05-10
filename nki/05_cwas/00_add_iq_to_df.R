#!/usr/bin/env Rscript

# This script combines the subject information I got online with
# IQ information on the same subjects from COINS.

basedir <- "/home2/data/Projects/CWAS"
scriptdir <- file.path(basedir, "share/nki")
subdir <- file.path(scriptdir, "subinfo")

Comment <- function(`@Comments`) {invisible()}

Comment(`
    > ddply(df, .(diagnosis, sex), function(x) c(N=nrow(x)))
    diagnosis    sex  N
  1    ADHD-C Female 10
  2    ADHD-C   Male 44
  3    ADHD-I Female 12
  4    ADHD-I   Male 24
  5       TDC Female 35
  6       TDC   Male 35
  
  # we have an even match of TDC, 
`)
