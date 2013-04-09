# This script will split the subjects's into 2 equal groups.

## Setup
library(plyr)
basedir <- "/home/data/Projects/CWAS"
sdir <- file.path(basedir, "share/age+gender/subinfo")
df <- read.csv(file.path(sdir, "03_details.csv"))

# I have fixed up the site labels here to be more pretty as well as various other labels...proly should have done this earlier.

## capitalize and titalize functions
source("/home/data/Projects/CWAS/share/lib/capitalize.R")

## Site
site <- as.character(df$site)
site <- gsub("_", " ", site)
site <- titalize(site)
site <- gsub("Ann Arbor A", "Ann Arbor", site)
site <- gsub("Beijing$", "Beijing A", site)
site <- gsub("BeijingEOEC", "Beijing B", site)
site <- gsub("New York A Adhd", "New York A", site) # collapsing New York A here...check if ok
site <- gsub("QuironValencia", "Quiron-Valencia", site)
site <- gsub("SaintLouis", "Saint Louis", site)
site <- gsub("VirginiaTech", "Virginia Tech", site)
df$orig_site <- df$site
df$site <- factor(site)

## Sex
sex <- as.character(df$sex)
sex <- gsub("M", "Male", sex)
sex <- gsub("F", "Female", sex)
df$sex <- factor(sex)

## Eyes
eyes <- capitalize(df$eyes)
eyes[eyes==""] <- NA
eyes[df$site=="Rockland"] <- "Open"
eyes[grep("New York", df$site)] <- "Open"
df$eyes <- factor(eyes)

## Handedness
handedness <- as.character(df$handedness)
handedness <- gsub("A", "Ambidextrous", handedness)
handedness <- gsub("L", "Left-Handed", handedness)
handedness <- gsub("R", "Right-Handed", handedness)
handedness[handedness==""] <- NA
df$handedness <- factor(handedness)

## Run
run <- as.numeric(df$run)
run <- factor(run, labels=c("Run 1", "Run 2", "Run 3"))
df$run <- run

## Save
write.csv(df, file=file.path(sdir, "03_details_touse.csv"), row.names=F)


## Split Groups
df <- cbind(index=1:nrow(df), df) # add index in case want to easily go backwards
new_df <- ddply(df, .(site, sex), function(sdf) {
    sdf <- sdf[order(sdf$age),]
    n <- nrow(sdf)
    labels <- c("Discovery Sample", "Replication Sample")
    sdf$sample <- rep(sample(labels), length.out=n)
    for (i in seq(1,n,by=2)) {
        if (n < (i+1)) next
        sdf$sample[i:(i+1)] <- sample(sdf$sample[i:(i+1)])
    }
    sdf
})


# Save three different data frames and functional file paths.

## all
func.all <- file.path(new_df$outdir, 
                    "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz")
write.table(func.all, file=file.path(sdir, "04_all_funcpaths.txt"), 
                                row.names=F, col.names=F)
write.csv(new_df, file=file.path(sdir, "04_all_df.csv"), row.names=F)

## discovery
df.discovery <- subset(new_df, new_df$sample == "Discovery Sample")
func.discovery <- file.path(df.discovery$outdir, 
                    "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz")
write.csv(df.discovery, file=file.path(sdir, "04_discovery_df.csv"), 
            row.names=F)
write.table(func.discovery, file=file.path(sdir, "04_discovery_funcpaths.txt"), 
            row.names=F, col.names=F)

## replication
df.replication <- subset(new_df, new_df$sample == "Replication Sample")
func.replication <- file.path(df.replication$outdir, 
                        "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz")
write.csv(df.replication, file=file.path(sdir, "04_replication_df.csv"), 
            row.names=F)
write.table(func.replication, file=file.path(sdir, "04_replication_funcpaths.txt"), 
            row.names=F, col.names=F)


