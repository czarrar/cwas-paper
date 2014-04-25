#!/usr/bin/env Rscript

# This script will take out the participant below from everything!
# and then resave

# Paths
basedir <- "/home2/data/Projects/CWAS/share/nki"
subinfo <- file.path(basedir, "subinfo")
roidir <- "/home2/data/Projects/CWAS/nki/rois"

# Scan stuff
scan_folders <- c("40_Set1_N104", "40_Set2_N92")

# Subject
bad_subject <- "M10982376"

# Loop through
for (folder in scan_folders) {
    cat("changing directory\n")
    cat(file.path(subinfo, folder), "\n")
    setwd(file.path(subinfo, folder))
    
    txt_files <- list.files(pattern="txt$")
    csv_files <- list.files(pattern="csv$")
    
    if (!file.exists("archive")) {
        cat("creating + copying stuff\n")
        dir.create("archive", FALSE)
        file.copy(txt_files, file.path("archive", txt_files))
        file.copy(csv_files, file.path("archive", csv_files))
    }
    
    cat("textify\n")
    for (txt_file in txt_files) {
        cat("-", txt_file, "\n")
        txt <- as.character(read.table(txt_file)[,1])
        find <- grep(bad_subject, txt)
        if (length(find) > 0) {
            cat("-- replacing\n")
            txt <- txt[-find]
            write.table(txt, file=txt_file)
        }
    }
    
    cat("csvify\n")
    for (csv_file in csv_files) {
        cat("-", csv_file, "\n")
        csv <- read.csv(csv_file)
        find <- grep(bad_subject, csv$Id)
        if (length(find) > 0) {
            cat("-- replacing\n")
            csv <- csv[-find,]
            row.names(csv) <- 1:nrow(csv)
            write.csv(csv, file=csv_file)
        }
    }
}
