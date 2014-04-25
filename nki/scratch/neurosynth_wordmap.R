#!/usr/bin/env Rscript

#' Here we create a word cloud for all the terms within regions found 
#' significant in the IQ CWAS using 3200 ROIs.

#' # Reading data

#+ setup
suppressPackageStartupMessages(library(niftir))
library(wordcloud)
library(RColorBrewer)
base <- "/home2/data/Projects/CWAS"
mask_file <- "/usr/share/fsl/4.1/data/standard/MNI152_T1_2mm_brain_mask.nii.gz"
logp_file <- file.path(base, "nki/cwas/short/compcor_rois_random_k3200/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/clust_logp_FSIQ_2mm.nii.gz")
ri_file <- file.path(base, "neurosynth/ri_maps.nii.gz")
term_file <- file.path(base, "neurosynth/reverse_inference_01_terms_touse.csv")

#+ read
mask <- read.mask(mask_file)
ri.maps <- read.big.nifti(ri_file)
ri.maps <- ri.maps[,mask]
logps <- read.nifti.image(logp_file)[mask]
df <- read.csv(term_file)
df <- df[df$term!="neutral",]

#' Taking out terms that are related to anatomy or people's names.
#+ remove
terms <- df$term[df$X==1]
ri.maps <- ri.maps[df$X==1,]


#' # Summarizing data

#' I compute either the # of overlapping voxels with each term, 
#' or the average significance of overlapping voxels with each term.
#+ summarize
term.vals.uwt <- rowSums(ri.maps[,logps>0]>0)
term.vals.wt <- rowMeans(ri.maps[,logps>0])

#' Let's quickly see the top 20 terms for each summary measure.
#+ quickview
head(terms[order(term.vals.uwt, decreasing=TRUE)], 20)
head(terms[order(term.vals.wt, decreasing=TRUE)], 20)


#' # Visualize data

#' The first wordcloud is for the simple overlap measure
#' while the second wordcloud is from the weighted overlap measure.
#+ wordcloud
pal2 <- brewer.pal(8,"Dark2")
wordcloud(words=terms, freq=term.vals.uwt, 
          scale=c(3,.2), min.freq=sum(logps>0)*0.05, max.words=Inf, 
          random.order=FALSE, rot.per=0.15, colors=pal2)
wordcloud(words=terms, freq=term.vals.wt, 
          scale=c(3,.2), min.freq=sum(logps>0)*0.2, max.words=Inf, 
          random.order=FALSE, rot.per=0.15, colors=pal2)

