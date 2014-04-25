#!/usr/bin/env Rscript

# I ended up using this script more for testing
# so things might be a bit all over the place



# So we can see here that we need some code to take the formula, 
# subdists (data), and indices
# This function would then need to
# - generate the gower matrix from the subject distances
# - determine the superblocksize and blocksize (maybe defaults?)
# - went to autoset factors2perm
# - have the model already present in the function or maybe as a global
# all the other options I think I can set with some defaults
# then we can call the mdmr function
# We should check how well the output works when I have a vector...it seems like yes
# So the output would be to take only
# - the pvals or fstats

library(connectir)
library(boot)

boot_mdmr <- function(formula, data, indices, sdist, factors2perm) {
    ###
    # Distances
    ###
    
    print(indices)
    
    # We need to sample the distances based on the indices
    # This will also create a local copy of the big matrix
    cat("Subset of subjects in distances\n")
    sdist <- filter_subdist(sdist, subs=indices)
    
    # Now we can gowerify
    cat("Gowerify\n")
    gmat <- gower.subdist2(sdist)
    
    # Size
    nvoxs <- ncol(gmat)
    nsubs <- sqrt(nrow(gmat))
    nperms <- 4999
    nfactors <- 1
    
    
    ###
    # Calculate memory demands
    ###
    opts <- list(verbose=TRUE, memlimit=20, blocksize=0, superblocksize=0)
    opts <- get_mdmr_memlimit(opts, nsubs, nvoxs, nperms, nfactors)
    
    
    ###
    # Get the model ready
    ###
    
    cat("Subset of subjects in model\n")
    model <- data.frame(data[indices,])
    
    
    ###
    # Call MDMR
    ###
    
    ret <- mdmr(gmat, formula, model, nperms, factors2perm, 
                 superblocksize=opts$superblocksize, blocksize=opts$blocksize)
    
    ret$pvals[,] # or ret$fstats or qt(ret$pvals, Inf, lower.tail=FALSE)
}


###
# TESTING
###

# Set parallel processing
nthreads <- 8
set_parallel_procs(1, nthreads, TRUE)

# Read in the distances
#dpath <- "/home2/data/Projects/CWAS/nki/cwas/short/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08/subdist.desc"
dpath <- "/home2/data/Projects/CWAS/nki/cwas/short/compcor_only_rois_random_k0800/subdist.desc"
sdist <- attach.big.matrix(dpath)

# Read in the model
mpath <- "/home2/data/Projects/CWAS/share/nki/subinfo/40_Set1_N104/subject_info_with_iq_and_gcors.csv"
model <- read.csv(mpath)
model <- subset(model, select=c("FSIQ", "Age", "Sex", "short_meanFD"))

# Set the formula
f     <- ~ FSIQ + Age + Sex + short_meanFD

## get subsample of the distances?
#sub.sdist <- sub.big.matrix(sdist, firstCol=1, lastCol=10, backingpath=dirname(dpath))

# Now do a test call (only 4)
results <- boot(data=model, statistic=boot_mdmr, R=4, formula=f, sdist=sdist, factors2perm="FSIQ")


## The indices from stdout (manually recorded them...)

inds1 <- scan()
25  21  45  19  76  34  10  40  40  68  98  71  23  80  53  28  61   5  79 100  45  28  19
9  32 101  75  95  77  15  41  39  64  35   8  39  11  87  36  66  41  14  31  56  27   8
12  64  31  98  92   5  96  44  88  24  69  20  40  95  39  48  60   5 100  57  62  37   3
66  26  23  34  44  15  11  27  26  84  56  91  73  17  28  48  32  20  11  31  67  85  75
33  78  31  82  14  68  49  42  67  15  90  55

inds2 <- scan()
53  19  59  60  36  54  63  42  55   9  36  64  25  28  99   4  61  46  45  74  95 102  14
72  21  74  45  21  52  96 100  50  20  16  58  54  19  58  49 103   7   4  70  79  17  33
20  58  40  41  56  45  19  53  82  96  70  64  27  51  56  66  19   5  94  43  20   6  23
103  62   8  48  23  56  66  56  98  82  20   5  74  16  93  77  77  79  77  53  30  42  84
59  87  13  58  45   7  28  40   9  62  19  50

inds3 <- scan()
60 101  23  81  61  40  59  84  12  90  48  33  74  72  33  14 103 100  63  71  35   7  69
94  58  64  89  87  73  40  84  65  75  60  12  55 100  19  85   7   1  70  36  24  43  26
104 104  31  17  88  78  85  60  50  64  62  19  72  30   7  16  15  56  28  13  98  70  49
6  20  14  83  37  64  46  79   6   1  37  33  52  45  36  83  50  49   3  15  83  71   3
47  44  42  93  99  51  96  43  33  39   6  52

inds4 <- scan() 
9  19  50  27  20  60  11  59  73  50  44  69  19  30  33  91  69 103  44  55 102  14 104
13  53 100 100  25  43  81  97   5   7  29  64  79  51  14  38  46  30  13  43  48  50   4
22  62  16  16 100  73  34  42  98 103  58  47  87  54  61  76  54  97   8  86  29  56  82
71  55  86  48  34 104  24  12  56  52  86  36  66  36   5  92  77  62  91 102  71  71  99
75  59  88   3   4  60  67  72  91  13  31  35

inds <- list(inds1, inds2, inds3, inds4)


## Now run similar bootstrap but without replacement
## I simply use a similar sampling removing any replicates (so smaller N)
ps.mat <- sapply(1:4, function(i) {
    cat("iteration", i, "\n")
    n <- length(unique(inds[[i]]))
    boot_mdmr(f, model, sample(1:104, n), sdist, "FSIQ")
})


## Let's save this data for comparison later
orig        <- results$t0
boot.repl   <- t(results$t)
boot.norepl <- ps.mat
save(orig, boot.repl, boot.norepl, file="/home2/data/Projects/CWAS/nki/bootstrap/compare_replication.rda")



# Will calculate dice pairwise between columns
# input `mat` should be boolean or integer of 0 and 1s
dice <- function(mat) {
    # (2*sum(a&b))/(sum(a)+sum(b))
    # 
    
    # This gets the number of elements in common between a & b
    sum.anb <- crossprod(mat)
    
    # We can get the sum in each set with the diagonal
    sum.a <- diag(sum.anb) %*% t(rep(1,ncol(mat)))
    sum.b <- t(sum.a)
    
    # Let's combine
    dice.mat <- (2*sum.anb)/(sum.a+sum.b)
    
    dice.mat
}

