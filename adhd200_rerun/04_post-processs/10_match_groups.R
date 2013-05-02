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
X <- as.integer(rownames(sdf))

# Match ADHD-C with TDC Females
inds.female.c <- sdf$diagnosis=="ADHD-C" & sdf$sex=="Female" # 10
inds.female.t <- sdf$diagnosis=="TDC" & sdf$sex=="Female"    # 35 => 10

comp.age <- sdf$age[inds.female.c]
inds.female.t.use <- c()
for (age in comp.age) {
    i <- which.min(abs(sdf$age[inds.female.t] - age))
    inds.female.t.use <- c(inds.female.t.use, X[inds.female.t][i])
    inds.female.t[inds.female.t][i] <- F
}

# Match ADHD-I with ADHD Females
inds.female.c <- sdf$diagnosis=="ADHD-C" & sdf$sex=="Female" # 10
inds.female.i <- sdf$diagnosis=="ADHD-I" & sdf$sex=="Female" # 12 => 10

comp.age <- sdf$age[inds.female.c]
inds.female.i.use <- c()
for (age in comp.age) {
    i <- which.min(abs(sdf$age[inds.female.i] - age))
    inds.female.i.use <- c(inds.female.i.use, X[inds.female.i][i])
    inds.female.i[inds.female.i][i] <- F
}

# Match ADHD-C with TDC Males
inds.male.c <- sdf$diagnosis=="ADHD-C" & sdf$sex=="Male" # 44 => 35
inds.male.t <- sdf$diagnosis=="TDC" & sdf$sex=="Male"    # 35

comp.age <- sdf$age[inds.male.t]
inds.male.c.use <- c()
for (age in comp.age) {
    i <- which.min(abs(sdf$age[inds.male.c] - age))
    inds.male.c.use <- c(inds.male.c.use, X[inds.male.c][i])
    inds.male.c[inds.male.c][i] <- F
}

# Combine
fdf <- rbind(
    sdf[sdf$diagnosis=="ADHD-I" & sdf$sex=="Male",],
    sdf[X %in% inds.female.i.use,],     # Note: was missing X %in% here...
    sdf[inds.female.c,], 
    sdf[X %in% inds.male.c.use,], 
    sdf[X %in% inds.female.t.use,], 
    sdf[inds.male.t,]
)

# As close as I could get with the two comparisons
Comment(`
    > ddply(fdf, .(diagnosis, sex), function(x) c(age=mean(x$age), n=nrow(x)))                                          
      diagnosis    sex      age  n
    1    ADHD-C Female 10.31200 10
    2    ADHD-C   Male 12.07400 35
    3    ADHD-I Female 10.76200 10
    4    ADHD-I   Male 12.77583 24
    5       TDC Female 10.25300 10
    6       TDC   Male 13.03571 35
`)

# Save
write.csv(fdf, file="../subinfo/30_subjects_matched.csv")
