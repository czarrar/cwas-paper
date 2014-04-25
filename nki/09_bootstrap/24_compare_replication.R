
#+ libraries
library(ggplot2)

#' loads 3 variables: orig, boot.repl, boot.norepl
#' These variables represent MDMR results for IQ using ROIs
#+ load
load("/home2/data/Projects/CWAS/nki/bootstrap/compare_replication.rda")

#' Will calculate dice pairwise between columns
#' input `mat` should be boolean or integer of 0 and 1s
#+ functions
dice <- function(mat) {
  # (2*sum(a&b))/(sum(a)+sum(b))

  # This gets the number of elements in common between a & b
  sum.anb <- crossprod(mat)
  
  # We can get the sum in each set with the diagonal
  sum.a <- diag(sum.anb) %*% t(rep(1,ncol(mat)))
  sum.b <- t(sum.a)
  
  # Let's combine
  dice.mat <- (2*sum.anb)/(sum.a+sum.b)
  
  dice.mat
}

#' Combine all the results together for plotting
#+ combine
nvoxs <- length(orig)
df <- data.frame(
    type    = rep(c("Original", rep("With Replication", 4), "Original", rep("Without Replication", 4)), each=nvoxs), 
    sample  = rep(rep(0:4, each=nvoxs), times=2), 
    pvals   = -log10(c(orig, as.vector(boot.repl), orig, as.vector(boot.norepl)))
)

#' # Distributions of Significance Maps
#'
#' Here I will plot histograms of the original and bootstrap data
#' where the data are whole-brain MDMR signifiance maps.
#' 
#' The bootstrap data can be with replication or without replication.
#' In the case, without replication I simply take the subject indices 
#' for the with replication case and find any duplicates and remove those.
#' This does mean that without replication has a lower N but it ensures
#' somewhat of a comparison between the two types of approaches.

#+ plot
ggplot(df, aes(x=pvals)) + 
    geom_histogram(binwidth=0.2) + 
    facet_grid(sample ~ type) + 
    xlab("MDMR -log10 p-values for IQ") + 
    ylab("Number of ROIs")

#' We can see from the histograms that the MDMR results are strangely 
#' distributed when using replication (with the package boot) relative to the 
#' original data or when I don't use replication. For some reason, 
#' with replication leads to many more significant results.
#' 
#' Indeed, when I looked at the voxelwise data around 95% of voxels in all the 
#' bootstrap samples were significant. (This isn't shown here).


#' # Comparisons
#'
#' Note that in the following comparisons it appears that using a bootstrap 
#' without replication ends up fairing better.

#' ## Dice
#' 
#' Dice amongst bootstrap with replication following by without replication.
#' Note here there are only 4 samples per group.

#+ dice
cat("With Replication\n")
dice(boot.repl)

cat("Without Replication\n")
dice(boot.norepl)


#' ## Correlation
#'
#' Same as with dice except using the spearman (rank-based) correlation

#+ correlation1
cat("With Replication\n")
cor(boot.repl, method="s")

cat("Without Replication\n")
cor(boot.norepl, method="s")

#' Now I look at the correlation with the original data
#+ correlation2
cat("With Replication\n")
cor(orig, boot.repl, method="s")

cat("Without Replication\n")
cor(orig, boot.norepl, method="s")


#' ## Percent of Signifiant ROIs
#' 
#' Wanted to see the percent of significant ROIs in each group.

#+ percent-sig
cat("Original\n")
round(mean(orig<0.05)*100)

cat("With Replication\n")
round(colMeans(boot.repl<0.05)*100)

cat("Without Replication\n")
round(colMeans(boot.norepl<0.05)*100)

#' As we observe above, the replication samples have extremely high proportion 
#' of significant ROIs. The without replication group has the least likely due
#' to lower power.
