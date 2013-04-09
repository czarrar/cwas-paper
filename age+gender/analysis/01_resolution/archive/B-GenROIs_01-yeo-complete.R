# This script will calculate connectivity between sub-cortical/cerebellum regions
# and the 7 cortical networks from the Yeo paper

library(Rsge)
library(connectir)
std_roidir <- "/home2/data/Projects/CWAS/rois"

# Number of jobs/threads/forks
njobs <- 24
nthreads <- 4
nforks <- 1
sge.options(sge.user.options = sprintf("-S /bin/bash -pe mpi_smp %i", nthreads*nforks))


###
# Load Shiz
###

# Load the brain mask
hdr <- read.nifti.header("rois/mask.nii.gz")
mask <- read.mask("rois/mask.nii.gz")

# Load the 7 Cortical Networks
seven_networks <- read.nifti.image(file.path(std_roidir, "yeo_7networks_3mm.nii.gz"))
seven_networks <- seven_networks[mask]
network_inds <- sort(unique(seven_networks[seven_networks!=0]))

# Get voxels that are not defined in the brain mask
define_voxels <- seven_networks==0

## Load the Cerebellum+SubCortical
#cerebellum_subcortical <- read.nifti.image(file.path(std_roidir, "mask_cerebellum+subcortical_3mm.nii.gz"))
#cerebellum_subcortical <- cerebellum_subcortical[mask]
## remove any voxels that have already been defined
#cerebellum_subcortical[six_networks>0] <- 0

# Load functional paths
funcpaths <- as.character(read.table("z_funcpaths.txt")[,1])


###
# Loop through subjects
# and get network membership for cerebellum/subcortical
###

subj.memberships <- sge.parLapply(funcpaths, function(funcpath) {
    set_parallel_procs(nforks, nthreads, force=TRUE)
    
    # Read in functional data
    func <- read.big.nifti4d(funcpath)
    func_masked <- do.mask(func, mask)
    rm(func); invisible(gc(F,T))
    
    # Calculate mean time-series for each network
    rois <- sapply(network_inds, function(ni) 
                rowMeans(func_masked[,seven_networks==ni,drop=FALSE]))
    rois <- as.big.matrix(rois, shared=TRUE)
    
    # Restrict func_masked even further!
    func_wanted <- do.mask(func_masked, define_voxels)
    rm(func_masked); invisible(gc(F,T))
    
    # Scale time-series data
    invisible(scale_fast(rois, to.copy=FALSE))
    invisible(scale_fast(func_wanted, to.copy=FALSE))
    
    # Compute correlation between each voxel in cerebellum/sub-cortical
    # and the 7 networks
    cormat <- big_cor(func_wanted, rois)
    
    # Get likely network that the voxel is a part-of
    membership <- apply(cormat, 1, which.max)
    
    return(membership)
}, packages=c("connectir"), function.savelist=ls(), njobs=njobs)
subj.memberships <- sapply(subj.memberships, function(x) x)


###
# Decide on network membership based on majority voting (across subjects)
###

group.memberships <- aaply(subj.memberships, 1, function(m) {
    tab <- table(m)
    as.numeric(names(which.max(tab)))
}, .progress="text")


###
# Save
###

all_networks <- seven_networks
all_networks[define_voxels] <- group.memberships
write.nifti(all_networks, hdr, mask, outfile="rois/yeo_7networks_3mm.nii.gz", overwrite=TRUE)

# split each network and save it
network.names <- c("visual", "somatomotor", "dorsal_attention", "ventral_attention", 
                    "limbic", "frontoparietal", "default")
for (i in 1:length(network.names)) {
    roi <- (all_networks == i) * 1
    write.nifti(roi, hdr, mask, outfile=sprintf("rois/yeo_%s_3mm.nii.gz", network.names[i]), overwrite=TRUE)
}
