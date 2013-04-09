library(connectir)

# Function to convert ROI results to be voxelwise
# note: this will be masked voxelwise results
rois_to_voxels <- function(rois, roi.data) {
    vox.data <- vector("numeric", length(rois))
    urois <- sort(unique(rois))
    
    for (i in 1:length(urois)) {
        ur <- urois[i]
        vox.data[rois==ur] <- roi.data[i]
    }
    
    return(vox.data)
}

# Script Directory
scriptdir <- "/home2/data/Projects/CWAS/share/age+gender/analysis/04_compare_to_glm/rois"

# Directory with many results
resdir <- "/home2/data/Projects/CWAS/age+gender/04_compare_to_glm/glm"



###
# Similarity
###

## DISCOVERY

sample <- "discovery"

# GLM Directory
glmdir <- file.path(resdir, sprintf("%s_rois_random_k3200", sample))
setwd(glmdir)

# Path to inputs
evs_file <- "model_evs.txt"
mask_file <- "mask2.nii.gz"
tvals_age_file <- "tvals_01.desc"
tvals_sex_file <- "tvals_03.desc"
roi_file <- file.path(scriptdir, "rois_random_k3200.nii.gz")
    
# Read in Stuff
evs <- read.table(evs_file)
mask <- read.mask(mask_file)
hdr <- read.nifti.header(mask_file)
rois <- read.nifti.image(roi_file)[mask]
discovery.tvals.age <- attach.big.matrix(tvals_age_file)
discovery.tvals.sex <- attach.big.matrix(tvals_sex_file)

# Convert to matrix
discovery.tvals.age <- discovery.tvals.age[,]
discovery.tvals.sex <- discovery.tvals.sex[,]


## REPLICATION

sample <- "replication"

# GLM Directory
glmdir <- file.path(resdir, sprintf("%s_rois_random_k3200", sample))
setwd(glmdir)

# Path to inputs
evs_file <- "model_evs.txt"
mask_file <- "mask2.nii.gz"
tvals_age_file <- "tvals_01.desc"
tvals_sex_file <- "tvals_03.desc"
roi_file <- file.path(scriptdir, "rois_random_k3200.nii.gz")
    
# Read in Stuff
evs <- read.table(evs_file)
mask <- read.mask(mask_file)
hdr <- read.nifti.header(mask_file)
rois <- read.nifti.image(roi_file)[mask]
replication.tvals.age <- attach.big.matrix(tvals_age_file)
replication.tvals.sex <- attach.big.matrix(tvals_sex_file)

# Convert to matrix
replication.tvals.age <- replication.tvals.age[,]
replication.tvals.sex <- replication.tvals.sex[,]


## COMPARE SIMILARITY DISCOVERY/REPLICATION

nrois <- ncol(replication.tvals.age)
consistency.age <- sapply(1:nrois, function(ri) {
    cor(discovery.tvals.age[,ri], replication.tvals.age[,ri], method="s")
})
consistency.sex <- sapply(1:nrois, function(ri) {
    cor(discovery.tvals.sex[,ri], replication.tvals.sex[,ri], method="s")
})


## Save similarity output

setwd("/home2/data/Projects/CWAS/age+gender/04_compare_to_glm")

consistency <- list(age=consistency.age, sex=consistency.sex)

save(consistency, file="comparison/tvals_consistency.rda")

names <- c("age", "sex")
for (name in names) {
    vcat(T, "Name: %s", name)
    
    ofile <- sprintf("nifti/tvals_consistency_%s.nii.gz", sub("[.]", "_", name))
    img <- rois_to_voxels(rois, consistency[[name]])
    write.nifti(img, hdr, mask, outfile=ofile)    
}
