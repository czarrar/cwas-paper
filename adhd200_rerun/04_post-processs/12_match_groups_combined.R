# This script will filter the subjects to be used
# and match the groups

library(plyr)
Comment <- function(`@Comments`) {invisible()}

# Setup
basedir <- "/home2/data/Projects/CWAS/share/adhd200_rerun"
subdir <- file.path(basedir, "subinfo")
subfile <- file.path(subdir, "20_subjects_qc.csv")

# Read
df <- read.csv(subfile)

# Remove ADHD-HI (really only one)
df <- df[df$diagnosis!="ADHD-HI",]
df$diagnosis <- factor(df$diagnosis)

# What do we have left
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

sdf <- df
X <- 1:nrow(sdf)

# Combine the ADHD sub-groups
groups <- as.character(sdf$diagnosis)
groups[groups %in% c("ADHD-C", "ADHD-I")] = "ADHD"
sdf$diagnosis <- factor(groups)

# What do we have now
Comment(`
    > ddply(sdf, .(diagnosis, sex), function(x) c(N=nrow(x), age=mean(x$age)))
    diagnosis    sex  N      age
  1      ADHD Female 22 10.82500
  2      ADHD   Male 68 11.80721
  3       TDC Female 35 12.64229
  4       TDC   Male 35 13.03571
`)

# Match the two groups on age and sex as best as you can
## Females
inds.tdc.female <- sdf$diagnosis=="TDC" & sdf$sex=="Female"      # 35
inds.adhd.female <- sdf$diagnosis=="ADHD" & sdf$sex=="Female"   # 22
comp.age <- sdf$age[inds.adhd.female]
inds.tdc.female.use <- c()
for (age in comp.age) {
    i <- which.min(abs(sdf$age[inds.tdc.female] - age))
    inds.tdc.female.use <- c(inds.tdc.female.use, X[inds.tdc.female][i])
    inds.tdc.female[inds.tdc.female][i] <- F
}
## Males
inds.adhd.male <- sdf$diagnosis=="ADHD" & sdf$sex=="Male"  # 68
inds.tdc.male <- sdf$diagnosis=="TDC" & sdf$sex=="Male"    # 35
comp.age <- sdf$age[inds.tdc.male]
inds.adhd.male.use <- c()
for (age in comp.age) {
    i <- which.min(abs(sdf$age[inds.adhd.male] - age))
    inds.adhd.male.use <- c(inds.adhd.male.use, X[inds.adhd.male][i])
    inds.adhd.male[inds.adhd.male][i] <- F
}

# New dataframe
fdf <- rbind(
    sdf[inds.adhd.male.use,], 
    subset(sdf, diagnosis=="ADHD" & sex=="Female"), 
    subset(sdf, diagnosis=="TDC" & sex=="Male"), 
    sdf[inds.tdc.female.use,]
)

# As close as I could get with the two comparisons
Comment(`
    > ddply(fdf, .(diagnosis, sex), function(x) c(n=nrow(x), age=mean(x$age)))
    diagnosis    sex  n      age
  1      ADHD Female 22 10.82500
  2      ADHD   Male 35 12.93886
  3       TDC Female 22 11.34227
  4       TDC   Male 35 13.03571
`)

# Save
write.csv(fdf, file="../subinfo/30_subjects_matched_combined.csv")
