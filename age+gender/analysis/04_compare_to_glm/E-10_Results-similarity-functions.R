# """
# Here lie functions to calculate the similarity between two vectors.
# 
# Vicky in her similarity quest has chosen three tools:
# 1. Dice
# 2. Pearson
# 3. Kendall's W
# """

# 1. DICE
dice <- function(a,b) {
    (2*sum(a&b))/sum(a+b)
}

dice.mat <- function(a, b=a, z=0) {
    xa <- a > z; xb <- b > z
    mat <- matrix(1, ncol(xa), ncol(xb))
    inds <- expand.grid(list(a=1:ncol(xa), b=1:ncol(xb)))
    for (ri in 1:nrow(inds)) {
        i <- inds[ri,1]; j <- inds[ri,2]
        mat[i,j] <- dice(xa[,i], xb[,j])
    }
    mat
}

# 2. Correlation (Pearson/Spearman)
## use corr function

# 3. Kendall's W
## use kendall_ref function in connectir

# ?. Concordance (although not used)
concordance.mat <- function(xa, xb=xa) {
    mat <- matrix(1, ncol(xa), ncol(xb))
    inds <- expand.grid(list(a=1:ncol(xa), b=1:ncol(xb)))
    for (ri in 1:nrow(inds)) {
        i <- inds[ri,1]; j <- inds[ri,2]
        mat[i,j] <- epi.ccc(xa[,i], xb[,j])$rho.c$est
    }
    mat
}
