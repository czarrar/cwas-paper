"""
This script will combine the GLM summary data with MDMR results
into a nice data frame that can be used for visualization.

Story:
    Vicki has her bags full.
"""

library(connectir)

# Directory with results and other stuff
base <- "/home2/data/Projects/CWAS"
mdmr.basedir <- file.path(base, "age+gender/03_robustness/cwas")
glm.basedir <- file.path(base, "age+gender/04_compare_to_glm/glm")
subinfodir <- file.path(base, "share/age+gender/analysis/04_compare_to_glm/subinfo")
odir <- file.path(base, "age+gender/04_compare_to_glm/comparison")
dir.create(odir)



## DISCOVERY

sample <- "discovery"


###
# Paths
###

# 1. Pheno Path
phenofile <- file.path(subinfodir, sprintf("04_%s_df.csv", sample))

# 2. MDMR Paths
sdistdir <- file.path(mdmr.basedir, sprintf("%s_rois_random_k3200", sample))
maskfile <- file.path(sdistdir, "mask2.nii.gz")
mdmrdir <- file.path(sdistdir, "age+gender_15k.mdmr")
pvalfile <- file.path(mdmrdir, "pvals.desc")

# 3. GLM Paths
glmdir <- file.path(glm.basedir, sprintf("%s_rois_random_k3200", sample))
glmfile <- file.path(glmdir, "summary", "all_sums.rda")


###
# Read
###

# 1. Load Phenotypic Data (not needed...not sure why still here)
phenos <- read.csv(phenofile)

# 2. Load GLM Summary
load(glmfile)
glm.wt <- wt
glm.uwt <- uwt
## split up (only use uncorrected)
glm.wt.age <- glm.wt$age
glm.wt.sex <- glm.wt$sex
glm.uwt.age <- glm.uwt$age
glm.uwt.sex <- glm.uwt$sex

# 3. Load MDMR Results
mdmr.pvals <- attach.big.matrix(pvalfile)[,]
mdmr.fdr.pvals <- p.adjust(mdmr.pvals, "fdr")
mdmr.fdr.pvals <- matrix(mdmr.fdr.pvals, nrow(mdmr.pvals), ncol(mdmr.pvals))
mdmr.fdr.log.pvals <- -log10(mdmr.fdr.pvals)
## split up
mdmr.fdr.age <- mdmr.fdr.log.pvals[,1]
mdmr.fdr.sex <- mdmr.fdr.log.pvals[,2]


###
# Combine
###

nrois <- length(glm.wt.age)
nvoxs <- sum(read.mask(maskfile))
discovery.df <- data.frame(
    sample = rep(sample, nrois*2), 
    factor = rep(c("age", "sex"), each=nrois), 
    roi = rep(1:nrois, 2), 
    mdmr = c(mdmr.fdr.age, mdmr.fdr.sex), 
    glm.wt = c(glm.wt.age, glm.wt.sex), 
    glm.uwt = (c(glm.uwt.age, glm.uwt.sex)/nvoxs)*100
)



## REPLICATION

sample <- "replication"


###
# Paths
###

# 1. Pheno Path
phenofile <- file.path(subinfodir, sprintf("04_%s_df.csv", sample))

# 2. MDMR Paths
sdistdir <- file.path(mdmr.basedir, sprintf("%s_rois_random_k3200", sample))
mdmrdir <- file.path(sdistdir, "age+gender_15k.mdmr")
pvalfile <- file.path(mdmrdir, "pvals.desc")

# 3. GLM Paths
glmdir <- file.path(glm.basedir, sprintf("%s_rois_random_k3200", sample))
glmfile <- file.path(glmdir, "summary", "all_sums.rda")


###
# Read
###

# 1. Load Phenotypic Data (not needed...not sure why still here)
phenos <- read.csv(phenofile)

# 2. Load GLM Summary
load(glmfile)
glm.wt <- wt
glm.uwt <- uwt
## split up (only use uncorrected)
glm.wt.age <- glm.wt$age
glm.wt.sex <- glm.wt$sex
glm.uwt.age <- glm.uwt$age
glm.uwt.sex <- glm.uwt$sex

# 3. Load MDMR Results
mdmr.pvals <- attach.big.matrix(pvalfile)[,]
mdmr.fdr.pvals <- p.adjust(mdmr.pvals, "fdr")
mdmr.fdr.pvals <- matrix(mdmr.fdr.pvals, nrow(mdmr.pvals), ncol(mdmr.pvals))
mdmr.fdr.log.pvals <- -log10(mdmr.fdr.pvals)
## split up
mdmr.fdr.age <- mdmr.fdr.log.pvals[,1]
mdmr.fdr.sex <- mdmr.fdr.log.pvals[,2]


###
# Combine
###

nrois <- length(glm.wt.age)
nvoxs <- sum(read.mask(maskfile))
replication.df <- data.frame(
    sample = rep(sample, nrois*2), 
    factor = rep(c("age", "sex"), each=nrois), 
    roi = rep(1:nrois, 2), 
    mdmr = c(mdmr.fdr.age, mdmr.fdr.sex), 
    glm.wt = c(glm.wt.age, glm.wt.sex), 
    glm.uwt = (c(glm.uwt.age, glm.uwt.sex)/nvoxs)*100
)


### CONSISTENCY

# GLM Consistency Path
constfile <- file.path(odir, "tvals_consistency.rda")

# Load GLM Consistency Results
load(constfile)
const.age <- consistency$age
const.sex <- consistency$sex


### COMBINE

# combine
df <- rbind(discovery.df, replication.df)
df$consistency <- c(const.age, const.age, const.sex, const.sex)
write.csv(df, file=file.path(odir, "01_dataframe_glm+mdmr.csv"))

