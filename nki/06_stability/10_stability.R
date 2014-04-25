#!/usr/bin/env Rscript

# This script will measure the reproducibility of the distance matrices across scan sessions

# Given the subject distance name
# and the three scan directories
#
# when scans are short and medium
# will filter to be only 92 subs
# 
# then will go through each voxel
# and measure the kendall's W
# across distances of the 3 scans
# 
# will save the output

suppressPackageStartupMessages(library(connectir))
set_parallel_procs(1, 12, T)

vcat(T, "Setup")
base <- "/home2/data/Projects/CWAS"

subdist.name <- "compcor_kvoxs_smoothed_to_kvoxs_smoothed"
res <- 4
set_parallel_procs()

outdir <- file.path(base, "nki", "stability", subdist.name)
if (file.exists(outdir)) vstop("output '%s' already exists", outdir)
dir.create(outdir)

nsubs <- 92; nscans <- 3
cwas.base <- file.path(base, "nki", "cwas")
scans <- c("short", "medium", "long")

subdist.dirs <- file.path(cwas.base, scans, subdist.name)
names(subdist.dirs) <- scans
if (!all(file.exists(subdist.dirs)))
    stop("subdist dirs do not all exist")


##################################
# Read Inputs

vcat(T, "Read Inputs")
sdists <- list()

vcat(T, "...reading in brain mask")
maskfile <- file.path(base, "nki", "rois", sprintf("mask_gray_%imm.nii.gz", res))
hdr <- read.nifti.header(maskfile)
mask <- read.mask(maskfile)
nvoxs <- sum(mask)
n <- nvoxs

vcat(T, "...reading in subject info")
df <- read.csv(file.path(base, "share/nki/subinfo/40_Set1_N104/subject_info_with_iq.csv"))
select.subs <- which(df$all == 3)
if (length(select.subs) != nsubs) vstop("select.subs not equaling %s, damn", nsubs)

vcat(T, "...reading & maybe filtering distances")
for (i in 1:nscans) {
    sdist.file <- file.path(subdist.dirs[i], "subdist.desc")
    sdist <- attach.big.matrix(sdist.file)
    if (i == 3) {
        vcat(T, "...%s - just read", scans[i])
        sdists[[i]] <- deepcopy(sdist)
    } else {
        vcat(T, "...%s - read & filter", scans[i])
        sdists[[i]] <- filter_subdist(sdist, select.subs)
    }
    rm(sdist); invisible(gc(F,T))
}
names(sdists) <- scans

vcat(T, "...indices for lower-half of distance matrix")
if (sqrt(nrow(sdists$short)) != nsubs) stop("short distances has wrong number of subs")
matinds     <- matrix(1:nrow(sdists$short), nsubs, nsubs)
lowerinds   <- matinds[lower.tri(matinds)]
nlower <- length(lowerinds)

##################################


##################################
# Mean of Distances

vcat(T, "Mean of subject distances")
mean.dists <- laply(sdists, function(sdist) {
    tmpdist <- deepcopy(x=sdist, rows=lowerinds)
    means <- colmean(tmpdist)
    rm(tmpdist); gc(F,T)
    return(means)
}, .progress="text")

vcat(T, "...test")
m <- matrix(sdists[[1]][,1], nsubs, nsubs)
if (!(mean(m[lower.tri(m)]) == mean.dists[1,1]))
    stop("mean error")

vcat(T, "...saving")
for (i in 1:nscans) {
    outfile <- file.path(outdir, sprintf("mean_%s.nii.gz", scans[i]))
    write.nifti(mean.dists[i,], hdr, mask, outfile=outfile, overwrite=T)
}

##################################


##################################
# Standard Deviation of Distances

vcat(T, "Standard deviation of subject distances")
sd.dists <- laply(sdists, function(sdist) {
    tmpdist <- deepcopy(x=sdist, rows=lowerinds)
    sds <- colsd(tmpdist)
    rm(tmpdist); gc(F,T)
    return(sds)
}, .progress="text")

vcat(T, "...test")
m <- matrix(sdists[[1]][,1], nsubs, nsubs)
if (!all.equal(sd(m[lower.tri(m)]), sd.dists[1,1], check.attributes=F))
    stop("sd error")

vcat(T, "...saving")
for (i in 1:nscans) {
    outfile <- file.path(outdir, sprintf("sd_%s.nii.gz", scans[i]))
    write.nifti(sd.dists[i,], hdr, mask, outfile=outfile, overwrite=T)
}

##################################


##################################
# Coefficient of Variation of Distances

vcat(T, "CV of subject distances")
cv.dists <- sd.dists/mean.dists

vcat(T, "...saving")
for (i in 1:nscans) {
    outfile <- file.path(outdir, sprintf("cv_%s.nii.gz", scans[i]))
    write.nifti(cv.dists[i,], hdr, mask, outfile=outfile, overwrite=T)
}

##################################


##################################
# Reproducibility of Distances

vcat(T, "Reproducibility of subject distances")
ksmap <- laply(1:n, function(i) {
    dist.mat <- big.matrix(nlower, nscans)
    for (j in 1:length(sdists)) {
        bedeepcopy(x=sdists[[j]], x.rows=lowerinds, x.cols=i, y=dist.mat, y.cols=j)
    }
    kendall_cpp(dist.mat)   # return's kendall's w
}, .progress="text")

vcat(T, "...saving")
outfile <- file.path(outdir, "consistency.nii.gz")
write.nifti(ksmap, hdr, mask, outfile=outfile, overwrite=T)

##################################


###################################
## Reproducibility of Gowers
#
#vcat(T, "Reproducibility of gower's centered matrix")
#
#vcat(T, "...gower centering")
#gdists <- lapply(sdists, function(sdist) {
#    gower.subdist2(sdist, verbose=1, parallel=FALSE)
#})
#rm(sdists); invisible(gc(F,T))
#
#vcat(T, "Reproducibility of gower's distances")
#ksmap.gower <- laply(1:n, function(i) {
#    gower.mat <- big.matrix(nlower, nscans)
#    for (j in 1:length(gdists)) {
#        bedeepcopy(x=gdists[[j]], x.rows=lowerinds, x.cols=i, y=gower.mat, y.cols=j)
#    }
#    kendall_cpp(gower.mat)   # return's kendall's w
#}, .progress="text")
#
#vcat(T, "...saving")
#outfile <- file.path(outdir, "gower_consistency.nii.gz")
#write.nifti(ksmap, hdr, mask, outfile=outfile, overwrite=T)
