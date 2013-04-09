# This script attempt to collect a set of SUMA images
# and compiles them into one nice figure

library(jpeg)

basedir <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/combined_rois+voxelwise/suma_images_vary_threshold"
setwd(basedir)

# Get list of files
filenames <- list.files(pattern="^fdr_age_rois-to-voxel_k.*jpg")

# Parse ordering of images
# 035, 085, 135, 185

# I want to attach each filename with an ith and jth index
# in the matrix of images that will be plotted

# I can find the ith element, which are the rows or ROI sizes
is <- rep(NA, length(filenames))
## I only use a subset of ROI sizes for easy viz
num_ks <- c(50, 100, 200, 400, 800, 1600, 3200)
str_ks <- sprintf("k%04i", num_ks)
nks <- length(str_ks)
## Some of the values will remain an NA as they won't be used
for (i in 1:nks)
    is[grep(str_ks[i], filenames)] <- i

# I can find the jth element, which are the cols or Z-Scores
js <- rep(NA, length(filenames))
## I'll use a different subset of thresholds for age than sex
num_threshs <- c(2.0, 2.5, 3.0, 3.5)
str_threshs <- sprintf("thr%03i", as.integer((num_threshs - 1.65)*100))
nthreshs <- length(str_threshs)
for (j in 1:nthreshs)
    js[grep(str_threshs[j], filenames)] <- j

# Refine filenames, is, and js to not have NAs
# and combine into one dataframe
inds_to_keep <- !(is.na(is) | is.na(js))
mat.inds <- data.frame(filename=filenames, i=is, j=js)
mat.inds <- mat.inds[inds_to_keep,]
mat.inds$ind <- (mat.inds$i - 1) * nthreshs + mat.inds$j

# Create the window to plot everything into
plot.new()
## no margins
par(mar=c(0,0,0,0))
## window is 1000 x 1000 units
plot.window(c(0,1000),c(0,1000))

img_lat <- readJPEG(filenames[1])
img_med <- readJPEG(filenames[2])
rasterImage(img_lat, 0, 300, 1436/3, 300 + 744/3)
rasterImage(img_med, 1436/3, 300, 1436/3 + 1436/3, 300 + 744/3)

# rasterImage, xleft, ybottom, xright, ytop
# testing out plotting of rasterImage

# 
m <- matrix(1:(nks*nthreshs*4), nks*2, nthreshs*2, byrow=T)
layout(m, widths=c(0.5,0.5), heights=c(0.45,0.05,0.45,0.05))

# Setup the arrangement
m <- matrix(rep(1:(nks*nthreshs), each=2), nks*2, nthreshs*2, byrow=T)
layout(m, widths=rep(1/nthreshs,nthreshs), heights=rep(1/(nks*2),nks*2))
layout(m)

par(mfrow=c(1,2))
x1 = rnorm(100); x2 = rnorm(100); x3 = rnorm(100); x4 = rnorm(100)
par(mar = c(2,4,4,2) + 0.1)
hist(x1, xlab="", main="Group A")
hist(x2, xlab="", main="Group B")



plot(c(100, 250), c(300, 450), type = "n", xlab="", ylab="")



is <- 
js <- filenames[grep(str_threshs[1], filenames)]

