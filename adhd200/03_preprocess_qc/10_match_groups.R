# This script will filter the subjects to be used
# and match the groups

# Setup
basedir <- "/home2/data/Projects/CWAS/share/adhd200"
subdir <- file.path(basedir, "subinfo")
subfile <- file.path(subdir, "02_subject_info_all.csv")

# Read
df <- read.csv(subfile)

# Only want NYU
sdf <- subset(df, site=="NYU")

# Match ADHD-C with TDC Females
inds.female.c <- sdf$group=="ADHD-C" & sdf$gender=="Female" # 10
inds.female.t <- sdf$group=="TDC" & sdf$gender=="Female"    # 43 => 10

comp.age <- sdf$age[inds.female.c]
inds.female.t.use <- c()
for (age in comp.age) {
    i <- which.min(abs(sdf$age[inds.female.t] - age))
    inds.female.t.use <- c(inds.female.t.use, sdf$X[inds.female.t][i])
    inds.female.t[inds.female.t][i] <- F
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
    sdf[sdf$group=="ADHD-I",],
    sdf[inds.female.c,], 
    sdf[sdf$X %in% inds.female.t.use,], 
    sdf[sdf$X %in% inds.male.c.use,], 
    sdf[inds.male.t,]
)

# Save
write.csv(fdf, file="../subinfo/03_subjects_matched.csv")
