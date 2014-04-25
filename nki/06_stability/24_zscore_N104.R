#!/usr/bin/env Rscript
 
library(niftir)

# Jack collected the location to gate of newton
# It was a town that summarized the distances between participants of two scans
base  <- "/home2/data/Projects/CWAS"
indir <- file.path(base, "nki/stability/N104_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08")


# At the gate, Jack needed to find some individuals in question
# so he could z-score them.

## He first gathered the paths to those measures present in both scans
scans <- c("short", "medium")
measures <- c("mean", "sd", "cv")
fs <- unlist(lapply(measures, function(m) sprintf("%s_%s.nii.gz", m, scans)))
inpaths <- file.path(indir, fs)

## Then, he added on the one measure that actually compared the two scans
inpaths <- c(inpaths, file.path(indir, "consistency.nii.gz"))

## He also determined what each new individual would be called
## after being z-scored. It wasn't a very innovative naming system
outpaths <- sub(".nii.gz", "_zscore.nii.gz", inpaths)


# With the inpaths and outpaths in hand, Jack proceeded to read in the data

## since he was reading in a box for each person, he wanted a mask to determine
## exactly where in that box the person would be. so he summoned the mask.
maskfile <- file.path(base, "nki", "rois", "mask_gray_4mm.nii.gz")
hdr      <- read.nifti.header(maskfile)
mask     <- read.mask(maskfile)
nvoxs    <- sum(mask)

## he summons each image from the scroll of inpaths and masks (aka sculpts) it
images <- sapply(inpaths, function(f) read.nifti.image(f)[mask])


# All the people collected in a matrix of images
# jack can now z-score each of them

## walking by each person (column), he casts the scale spell
## to get the z-scores
zscore_images <- apply(images, 2, scale)


# The zscore images are now ready to be written to the disks of rocky

## jack sprinkles them one by one to the disks
for (i in 1:ncol(zscore_images)) {
    img     <- zscore_images[,i]
    outfile <- outpaths[i]
    write.nifti(img, hdr, mask, outfile=outfile)
}
