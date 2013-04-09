# This script will create the subinfo/01_subject_info.csv
# which is a data-frame with info on the subjects to be preprocessed

library(plyr)

# Phenotypic Keys
site_key <- c("Peking", "Brown", "KKI", "Neuroimage", "NYU", "OHSU", "UPitt", "WashU")
gender_key <- c("Female", "Male")
diagnosis_key <- c("TDC", "ADHD-C", "ADHD-HI", "ADHD-I")

# Read in the data frame
df <- read.csv("/home2/data/Originals/ADHD200/docs/zarrar_adhd200.csv")

# Format
newdf <- ddply(df, .(ScanDir.ID), function(line) {
    # Anatomical QC
    if (line$QC_Anatomical_1 == 1) {
        mprage.run <- 1
    } else if (line$QC_Anatomical_2 == 1) {
        mprage.run <- 2
    } else {
        mprage.run <- NA
    }
    
    # Functional QC
    if (line$QC_Rest_1 == 1) {
        rest.run <- 1
    } else if (line$QC_Rest_2 == 1) {
        rest.run <- 2
    } else if (line$QC_Rest_3 == 1) {
        rest.run <- 3
    } else if (line$QC_Rest_4 == 1) {
        rest.run <- 4    
    } else {
        rest.run <- NA
    }
    
    data.frame(
        id = sprintf("%07i", line$ScanDir.ID), 
        site = site_key[line$Site], 
        group = diagnosis_key[line$DX+1], 
        gender = gender_key[line$Gender+1][1], 
        age = line$Age, 
        iq = line$Full4.IQ, 
        anat.run = mprage.run, 
        rest.run = rest.run
    )
})
# replace IQ of -999 => NA
newdf$iq[!is.na(newdf$iq) & newdf$iq == -999] <- NA

# Filter out subjects without
olddf <- newdf
## gender
newdf <- subset(newdf, !is.na(newdf$gender))
## anatomical
newdf <- subset(newdf, !is.na(newdf$anat.run))
## functional
newdf <- subset(newdf, !is.na(newdf$rest.run))
## IQ
newdf <- subset(newdf, !is.na(newdf$iq))

# Only keep TDC, ADHD-C, and ADHD-I (take out ADHD-HI)
newdf <- subset(newdf, group %in% c("TDC", "ADHD-C", "ADHD-I"))
newdf$group <- factor(newdf$group)

# Take out UPitt since only using training data and in that only TDC
newdf <- subset(newdf, site != "UPitt")
newdf$site <- factor(newdf$site)

# Fix Peking site to be Peking1, Peking2, or Peking3
peking1 <- list.files("/home2/data/Originals/ADHD200/usable_copy/sorted/Peking_1")
peking2 <- list.files("/home2/data/Originals/ADHD200/usable_copy/sorted/Peking_2")
peking3 <- list.files("/home2/data/Originals/ADHD200/usable_copy/sorted/Peking_3")
newdf$site <- as.character(newdf$site)
newdf$site[newdf$id %in% peking1] <- "Peking1"
newdf$site[newdf$id %in% peking2] <- "Peking2"
newdf$site[newdf$id %in% peking3] <- "Peking3"
newdf$site[newdf$id=="3993793"] <- "Peking2"

# SAVE
write.csv(newdf, file="../subinfo/02_subject_info_all.csv")
