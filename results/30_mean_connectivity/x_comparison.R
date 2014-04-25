#!/usr/bin/env Rscript

library(niftir)
library(ggplot2)

dice <- function(a,b) (2*sum(a&b))/(sum(a)+sum(b))


###
# SETUP
###

# General Variables
base    <- "/home2/data/Projects/CWAS"
outdir  <- file.path(base, "figures/sfig_dev_motion_global")

# Basics
study   <- "development+motion"
prefix  <- file.path(base, study, "cwas")

# MDMR
mdmr_subpaths <- list(
    "compcor_age"               = "compcor_kvoxs_smoothed/age_sex+tr.mdmr", 
    "global_age"                = "global_kvoxs_smoothed/age_sex+tr.mdmr", 
    "compcor_age+gcor"          = "compcor_kvoxs_smoothed/age_sex+tr+meanGcor.mdmr", 
    "compcor_age+motion"        = "compcor_kvoxs_smoothed/age+motion_sex+tr.mdmr", 
    "global_age+motion"         = "global_kvoxs_smoothed/age+motion_sex+tr.mdmr", 
    "compcor_age+motion+gcor"   = "compcor_kvoxs_smoothed/age+motion_sex+tr+meanGcor.mdmr"
)

# Thresholded data
suffix_thr  <- "cluster_correct_v05_c05/easythresh/thresh_zstat_age.nii.gz"
logp_paths <- file.path(prefix, mdmr_subpaths, suffix_thr)
names(logp_paths) <- names(mdmr_subpaths)

# Unthresholded data
suffix_uthr <- "cluster_correct_v05_c05/easythresh/zstat_age.nii.gz"
ulogp_paths <- file.path(prefix, mdmr_subpaths, suffix_uthr)
names(ulogp_paths) <- names(mdmr_subpaths)

# Brain masks
mask_paths <- file.path(dirname(file.path(prefix, mdmr_subpaths)), "mask.nii.gz")
names(mask_paths) <- names(mdmr_subpaths)

# Number of files
n <- length(logp_paths)


###
# THRESHOLDED
###

cat("Thresholded Data\n")

# Read in the files
dat <- sapply(1:n, function(i) {
    logp_path <- logp_paths[i]
    mask_path <- mask_paths[i]
    logp <- read.nifti.image(logp_path)[read.mask(mask_path)]
    return(logp)
})
colnames(dat) <- names(mdmr_subpaths)

# Correlation
cat("...correlation\n")
p.dat <- cor(dat, method="s")
print(p.dat)

# Correlation
cat("...correlation masked\n")
m <- rowSums(dat>0) > 0
m.dat <- cor(dat[m,], method="s")
print(m.dat)

# Dice
cat("...dice\n")
d.dat <- sapply(1:n, function(i) {
    sapply(1:n, function(j) {
        dice(dat[,i]>0, dat[,j]>0)
    })
})
colnames(d.dat) <- row.names(d.dat) <- names(mdmr_subpaths)
print(d.dat)

# N voxels active
cat("...% voxels with significant associations\n")
n.dat <- colMeans(dat>0)
names(n.dat) <- names(mdmr_subpaths)
print(n.dat)


###
# UN-THRESHOLDED
###

cat("\n\nUn-Thresholded Data\n")

# Read in the files
dat <- sapply(1:n, function(i) {
    ulogp_path <- ulogp_paths[i]
    mask_path <- mask_paths[i]
    logp <- read.nifti.image(ulogp_path)[read.mask(mask_path)]
    return(logp)
})
colnames(dat) <- names(mdmr_subpaths)

# Correlation
cat("...correlation\n")
p.dat <- cor(dat, method="s")
print(p.dat)



###
# Save
###

write.table(m.dat, file=file.path(outdir, "B_thr_cors.txt"))
write.table(d.dat, file=file.path(outdir, "B_thr_dice.txt"))
write.table(n.dat, file=file.path(outdir, "B_thr_nvoxs.txt"))
write.table(p.dat, file=file.path(outdir, "B_unthr_cors.txt"))



###
# Generate Figures
###

library(corrgram)
library(RColorBrewer)

# New Names
new_names <- c("CC\nAge", "G\nAge", "CC\nAge+Mean", "CC\nAge+Motion", 
               "G\nAge+Motion", "CC\nAge+Motion+Mean")
colnames(m.dat) <- new_names
colnames(d.dat) <- new_names
colnames(p.dat) <- new_names
rownames(m.dat) <- new_names
rownames(d.dat) <- new_names
rownames(p.dat) <- new_names

panel.txt2 <- function (x = 0.5, y = 0.5, txt, cex, font) 
{
    text(x, y, txt, cex = cex, font = font, family="Lucida Sans")
}

# Function to display correlation text in upper panel
panel.txt3 <- function(x=0.5, y=0.5, corr=NULL, ...) {
	# Get correlation
    if (is.null(corr))
        stop("error")
    r <- corr
    
	# Get color of text
    ncol <- 5
    pal <- brewer.pal(12, "Paired")[c(6,5,9,1,2)]   # red, lt red, lt purple, lt blue, blue
    if (r>=0.5) col.ind <- 1
    if (r<0.5) col.ind <- 2
        
    # Format text
	r <- sprintf("%.2f", r)
	
	# Find center of plot
	usr <- par("usr")	# returns limits of plot
	xcenter <- usr[1] + diff(usr[1:2])/2
	ycenter <- usr[3] + diff(usr[3:4])/2

	# Put correlation value in center of plot
	text(xcenter, ycenter, r, cex=2.5, font=2, family="Lucida Sans", col=pal[col.ind])
}

# Do it figures...
x11()
corrgram(m.dat, type="corr", text.panel=panel.txt, upper.panel=panel.txt3, 
        lower.panel=panel.shade, col.regions=colorRampPalette(c("red","salmon","white")), 
        cex.labels=1.5, font.labels=2)
dev.copy(png, file.path(outdir, "B_thr_cors.png"))
dev.off()
dev.off()

x11()
corrgram(d.dat, type="cor", text.panel=panel.txt, upper.panel=panel.txt3, 
        lower.panel=panel.shade, col.regions=colorRampPalette(c("red","salmon","white")), 
        cex.labels=2, font.labels=2)
dev.copy(png, file.path(outdir, "B_thr_dice.png"))
dev.off()
dev.off()

x11()
corrgram(p.dat, type="cor", text.panel=panel.txt, upper.panel=panel.txt3, 
        lower.panel=panel.shade, col.regions=colorRampPalette(c("red","salmon","white")), 
        cex.labels=2, font.labels=2)
dev.copy(png, file.path(outdir, "B_unthr_cors.png"))
dev.off()
dev.off()

