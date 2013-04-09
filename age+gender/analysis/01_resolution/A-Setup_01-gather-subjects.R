# This script will get subjects from the rockland sample
# and match the gender for age
# It will also save the brain mask

# Gather all subjects
df <- read.csv("../../subinfo/04_all_df.csv")

# Refine to Rockland sample
df.rockland <- subset(df, site=="Rockland")

# Seperate the Sexes
df.male <- subset(df.rockland, sex=="Male")
df.female <- subset(df.rockland, sex=="Female")

# Sort by age
df.male <- df.male[order(df.male$age),]
df.female <- df.female[order(df.female$age),]

# Restrict the males
inds.male <- c()
for (i in 1:nrow(df.female)) {
    age.diff <- abs(df.male$age - df.female$age[i])
    o <- order(age.diff)
    w <- o[!(o %in% inds.male)][1]
    inds.male <- c(inds.male, w)    
}
df.male <- df.male[inds.male,]

# Re-combine
df <- rbind(df.male, df.female)

# Use compcor pre-processing
df$outdir <- gsub("linear1.wm1.motion1.csf1_CSF_0.98_GM_0.7_WM_0.98", "_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98", df$outdir)

# Save details
write.csv(df, file="z_details.csv")

# Save functional paths
funcpaths <- file.path(df$outdir, "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz")
write.table(funcpaths, file="z_funcpaths.txt", row.names=F, col.names=F)

# Modify handedness
handedness <- as.character(df$handedness)
handedness[handedness == "Ambidextrous"] <- "Left-Handed"
df$handedness <- factor(handedness)
write.csv(df, file="z_details2.csv", row.names=F)
