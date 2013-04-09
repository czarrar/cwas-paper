# This script will create (soft-link) a set of ROI files
# where across the different networks there is an equal number of voxels
# given a specified parcellation

library(niftir)

# ROI and Cluster Paths
rbase <- "/home2/data/Projects/CWAS/share/age+gender/analysis/01_resolution/rois"
cbase <- "/home2/data/Projects/CWAS/age+gender/01_resolution/spatial_cluster"

# Mask
hdr <- read.nifti.header(file.path(rbase, "mask.nii.gz"))
mask <- read.mask(file.path(rbase, "mask.nii.gz"))

# Number of voxels in each brain network
brain_networks <- read.nifti.image(file.path(rbase, "yeo_7networks_3mm.nii.gz"))[mask]
network.voxnums <- table(brain_networks)

# Number of clusters and names of networks
ks <- c(5,10,25,50,100,150,200,250,300,350,400,450,500,550,600)
network.names <- c("visual", "somatomotor", "dorsal_attention", "ventral_attention", 
                   "limbic", "frontoparietal", "default")

# Get the theoretical average size of each cluster
# and save the one that is the same across networks
network.vox_by_ks <- sapply(network.voxnums, function(vn) vn/ks)
ref <- which(network.voxnums == median(network.voxnums))
network.ks <- sapply(1:length(ks), function(i) {
    ks[apply(abs(network.vox_by_ks-network.ks[i,ref]), 2, which.min)]
})

# Now create a symlink between the actual network k
# and a new placeholder
for (ni in 1:length(network.names)) {
    for (ki in 1:length(ks)) {
        
        inclust <- file.path(cbase, sprintf("group_mean_scorr_cluster_%s_%i.nii.gz", 
                                                network.names[ni], ks[ki]))
        outclust <- file.path(cbase, sprintf("bysize_group_mean_scorr_cluster_%s_%02i.nii.gz", 
                                                network.names[ni], ki))
        file.symlink(inclust, outclust)
    }
    
}
