# This script will filter the subjects to be used
# and match the groups

# Setup
basedir <- "/home2/data/Projects/CWAS/share/adhd200"
subdir <- file.path(basedir, "subinfo")
subfile <- file.path(subdir, "03_subjects_qc.csv")

# Read
df <- read.csv(subfile)

# Only want NYU
sdf <- subset(df, site=="NYU")
sdf$X <- 1:nrow(sdf)

# Match ADHD-C with TDC Females
inds.female.c <- sdf$group=="ADHD-C" & sdf$gender=="Female" # 9
inds.female.t <- sdf$group=="TDC" & sdf$gender=="Female"    # 4? => 9

comp.age <- sdf$age[inds.female.c]
inds.female.t.use <- c()
for (age in comp.age) {
    i <- which.min(abs(sdf$age[inds.female.t] - age))
    inds.female.t.use <- c(inds.female.t.use, sdf$X[inds.female.t][i])
    inds.female.t[inds.female.t][i] <- F
}

# Match ADHD-I with ADHD Females
inds.female.c <- sdf$group=="ADHD-C" & sdf$gender=="Female"    # ?
inds.female.i <- sdf$group=="ADHD-I" & sdf$gender=="Female" # 11 => 9

comp.age <- sdf$age[inds.female.c]
inds.female.i.use <- c()
for (age in comp.age) {
    i <- which.min(abs(sdf$age[inds.female.i] - age))
    inds.female.i.use <- c(inds.female.i.use, sdf$X[inds.female.i][i])
    inds.female.i[inds.female.i][i] <- F
}

# Match ADHD-C with TDC Males
inds.male.c <- sdf$group=="ADHD-C" & sdf$gender=="Male" # 51 => 41
inds.male.t <- sdf$group=="TDC" & sdf$gender=="Male"    # 41

comp.age <- sdf$age[inds.male.t]
inds.male.c.use <- c()
for (age in comp.age) {
    i <- which.min(abs(sdf$age[inds.male.c] - age))
    inds.male.c.use <- c(inds.male.c.use, sdf$X[inds.male.c][i])
    inds.male.c[inds.male.c][i] <- F
}

# Combine
fdf <- rbind(
    sdf[sdf$group=="ADHD-I" & sdf$gender=="Male",],
    sdf[inds.female.i.use,], 
    sdf[inds.female.c,], 
    sdf[sdf$X %in% inds.male.c.use,], 
    sdf[sdf$X %in% inds.female.t.use,], 
    sdf[inds.male.t,]
)

# Save
write.csv(fdf, file="../subinfo/04_subjects_matched.csv")
