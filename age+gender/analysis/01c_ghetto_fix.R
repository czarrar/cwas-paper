# For some reason, I changed the funcpaths after running subdist so this script reverts things back

## Setup

basedir <- "/home/data/Projects/CWAS"
sdir <- file.path(basedir, "share/age+gender/subinfo")

# Load the changed list of all subjects
fname <- file.path(sdir, "03_details_touse.csv")
df <- read.csv(fname)

# Fix the paths and get the full func-file paths
base_files <- file.path(df$outdir, 
                        "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz")
base_files <- sub("/home2/", "/home/", base_files)
df$outdir <- sub("/home2/", "/home/", df$outdir)

# Load the currently used list of discovery subjects
# and compare in order to re-generate list above
load(file.path(basedir, "age+gender/cwas_discovery/options.rda"))
discovery_files <- as.character(opts$infiles)
d.w <- sapply(discovery_files, function(f) which(f==base_files))

# Same thing as above but for replication sample
load(file.path(basedir, "age+gender/cwas_replication/options.rda"))
replication_files <- as.character(opts$infiles)
r.w <- sapply(replication_files, function(f) which(f==base_files))

# Re-order the data-frame and save it
df <- df[c(d.w,r.w),]
file.rename(
    file.path(sdir, "03_details_touse.csv"), 
    file.path(sdir, "z_archive_03_details_touse.csv")
)
write.csv(df, file=file.path(sdir, "03_details_touse.csv"), row.names=F)

# Assign subjects into one of the two promised groups
df$sample <- rep(c("Discovery Sample", "Replication Sample"), c(length(d.w), length(r.w)))


## Equalizing the sample size between the two samples

# Remove 5 subjects from the Discovery Sample to make the groups even
# 1. gather the sites with the difference
diff.df <- ddply(df, .(site), function(x) {
    dn <- sum(x$sample=="Discovery Sample")
    rn <- sum(x$sample=="Replication Sample")
    c(difference=dn-rn)
})
diff.df <- diff.df[diff.df$difference>0,]
# 2. randomly choose 5 of the sites to have 1 subject removed
diff.df <- diff.df[sample(1:nrow(diff.df),5),]
# 3. select the 5 subjects from these 5 sites in the Discovery Sample
inds <- which((df$site %in% diff.df$site) & (df$sample == "Discovery Sample"))
inds <- tapply(inds, as.character(df$site[inds]), function(x) x[length(x)])
inds <- as.numeric(inds)
# 4. remove those subjects
new_df <- df[-inds,]
# 5. double check
check <- ddply(new_df, .(site), function(x) {
    dn <- sum(x$sample=="Discovery Sample")
    rn <- sum(x$sample=="Replication Sample")
    c(difference=dn-rn)
})
if (sum(check$difference) != 1) stop("Discovery and Replication Samples are Unequal")

# Need to also remove those 5 subjects from the discovery distance matrix
# save a csv file with this info and then use connectir_filter_subdist.R
w <- df$sample=="Discovery Sample"
sdist_filter <- data.frame(
                    sample  = df$sample[w], 
                    site    = df$site[w], 
                    keep    = T
                )
sdist_filter$keep[inds] <- F
write.csv(sdist_filter, file=file.path(sdir, "04a_discovery_sdist_fix.csv"), row.names=F)

# Will need to indepenently run the following to further deal with the issue
# 1. filter out these 5 subjects from the subdist
# 2. remove these 5 subjects from the input funcs directory
# 3. change infiles in options.rda to match the new infiles

## Create relevant files for each of the two samples

# generate seperate data-frames
df <- new_df
df.discovery <- subset(df, df$sample == "Discovery Sample")
df.replication <- subset(df, df$sample == "Replication Sample")

# generate seperate lists of file paths
func.discovery <- file.path(df.discovery$outdir, 
                                "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz")
func.replication <- file.path(df.replication$outdir, 
                                "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz")

# rename the old split group dfs and file paths
file.rename(file.path(sdir, "04_discovery_df.csv"), 
            file.path(sdir, "z_archive_04_discovery_df.csv"))
file.rename(file.path(sdir, "04_replication_df.csv"), 
            file.path(sdir, "z_archive_04_replication_df.csv"))
file.rename(file.path(sdir, "04_discovery_funcpaths.txt"), 
            file.path(sdir, "z_archive_04_discovery_funcpaths.txt"))
file.rename(file.path(sdir, "04_replication_funcpaths.txt"), 
            file.path(sdir, "z_archive_04_replication_funcpaths.txt"))

# save the split groups dfs and file paths
write.csv(df.discovery, file=file.path(sdir, "04_discovery_df.csv"), 
            row.names=F)
write.table(func.discovery, file=file.path(sdir, "04_discovery_funcpaths.txt"), 
            row.names=F, col.names=F)
write.csv(df.replication, file=file.path(sdir, "04_replication_df.csv"), 
            row.names=F)
write.table(func.replication, file=file.path(sdir, "04_replication_funcpaths.txt"), 
            row.names=F, col.names=F)
