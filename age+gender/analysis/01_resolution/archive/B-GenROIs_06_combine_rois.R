# This script will combine the ROIs across the different networks
# based on 2 approaches

library(niftir)


###
# Setup
###

# ROI and Cluster Paths
rbase <- "/home2/data/Projects/CWAS/share/age+gender/analysis/01_resolution/rois"
cbase <- "/home2/data/Projects/CWAS/age+gender/01_resolution/spatial_cluster"

# Mask
hdr <- read.nifti.header(file.path(rbase, "mask.nii.gz"))
mask <- read.mask(file.path(rbase, "mask.nii.gz"))

# Large-scale brain networks
# and make each network value by a factor of 1000
brain_networks <- read.nifti.image(file.path(rbase, "yeo_7networks_3mm.nii.gz"))[mask]
inds <- unique(brain_networks[brain_networks!=0])
for (ind in inds)
    brain_networks[brain_networks==ind] <- ind*1000

# Number of clusters and names of networks
ks <- c(5,10,25,50,100,150,200,250,300,350,400,450,500,550,600)
network.names <- c("visual", "somatomotor", "dorsal_attention", "ventral_attention", 
                   "limbic", "frontoparietal", "default")


###
# Approach 1: Combine by matching # of ROIs in each network
###

for (k in ks) {
    cat(sprintf("k %03i\n", k))
    roiset <- brain_networks*1
    for (ni in 1:length(network.names)) {
        name <- network.names[ni]
        cfile <- file.path(cbase, sprintf("group_mean_scorr_cluster_%s_%i.nii.gz", 
                                            name, k))
        netrois <- read.nifti.image(cfile)[mask]
        roiset <- roiset + netrois
    }
    ofile <- file.path(rbase, sprintf("rois_same_k%03i.nii.gz", k))
    write.nifti(roiset, hdr, mask, outfile=ofile)
}


###
# Approach 2: Combine by matching rough size of each ROI within a network
###

for (ki in 1:length(ks)) {
    cat(sprintf("ki %02i\n", ki))
    roiset <- brain_networks*1
    for (ni in 1:length(network.names)) {
        name <- network.names[ni]
        cfile <- file.path(cbase, sprintf("bysize_group_mean_scorr_cluster_%s_%02i.nii.gz", 
                                            name, ki))
        netrois <- read.nifti.image(cfile)[mask]
        roiset <- roiset + netrois
    }
    ofile <- file.path(rbase, sprintf("rois_samesize_%02i.nii.gz", ki))
    write.nifti(roiset, hdr, mask, outfile=ofile)
}

