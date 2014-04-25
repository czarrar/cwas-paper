
#' Setup
#+ setup
library(connectir)

basedir <- "/home2/data/Projects/CWAS"
subdir <- file.path(basedir, "share/nki/subinfo/40_Set1_N104")
roidir <- file.path(basedir, "rois/yeo_combined")

scans <- c("short", "medium")
subfiles <- file.path(subdir, sprintf("%s_compcor_funcpaths.txt", scans))
maskfile <- file.path(roidir, "grey_matter_mask_2mm.nii.gz")
roifile <- file.path(roidir, "partial_yeo_combined_2mm.nii.gz")

#' Read
#+ read
list.funcfiles <- lapply(subfiles, function(f) as.character(read.table(f)[,1]))
names(list.funcfiles) <- scans
list.maskfiles <- lapply(list.funcfiles, function(ff) {
  file.path(dirname(dirname(ff)), "functional_brain_mask_to_standard.nii.gz")
})
mask <- read.mask(maskfile)
hdr <- read.nifti.header(maskfile)
rois <- read.nifti.image(roifile)[mask]
urois <- sort(unique(rois[rois!=0]))

#' # Subject Connectivity
#' Here I'll go through each participant...
#+ connectivity
funcfiles <- list.funcfiles$short
maskfiles <- list.maskfiles$short

subs.networks <- laply(1:length(funcfiles), function(j) {
  func <- read.big.nifti4d(funcfiles[j])
  func <- do.mask(func, mask)
  
  subj.mask <- read.mask(maskfiles[j])[mask]
  func <- do.mask(func, subj.mask)
  
  # Get average time-series in each network
  subj.rois <- rois[subj.mask]
  mean.rois.ts <- sapply(urois, function(ur) {
    rowMeans(func[,subj.rois==ur])
  })
  
  # Get undefined voxels and compute correlation with networks
  empty.voxs <- subj.rois == 0
  network.conns <- cor(func[,empty.voxs], mean.rois.ts)
  
  # Choose maximum network connectivity
  choose.network <- apply(network.conns, 1, which.max)
  
  # Return results
  voxs <- subj.mask*0
  voxs[subj.mask][empty.voxs] <- choose.network
  
  rm(func); invisible(gc(F,T))
  
  return(voxs)
}, .progress="text")

#' Find most common network across subjects for each empty voxel
#+ combine
grp.networks <- aaply(subs.networks, 2, function(vec) {
  if (mean(vec==0) > 0.75) {
    ret <- 0
  } else {
    tab <- table(vec[vec!=0])
    ret <- as.numeric(names(which.max(tab)))
  }
  #print(ret)
  ret
}, .progress="text")

#' Save the non-empty network connections
#' and combine with yeo networks and save that
#+ save
write.nifti(grp.networks, hdr, mask, outfile=file.path(roidir, "zarrar_2mm.nii.gz"))
all.rois <- rois + grp.networks
write.nifti(all.rois, hdr, mask, outfile=file.path(roidir, "all_7networks_2mm.nii.gz"))

