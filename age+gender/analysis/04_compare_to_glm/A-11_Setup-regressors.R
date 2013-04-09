# This script will read in the data frames and create regressors and contrasts for GLM

scriptdir <- "/home2/data/Projects/CWAS/share/age+gender/analysis/04_compare_to_glm"
setwd(scriptdir)


###
# Discovery Sample
###

# Read in model
model <- read.csv("subinfo/04_discovery_df.csv")

# Setup formula
formula <- . ~ site + run + mean_FD + age + sex
formula[[2]] <- NULL

# Create regressors
rhs.frame <- model.frame(formula, model, drop.unused.levels = TRUE)
if (nrow(rhs.frame) != nrow(model))
    vstop("One of your factors has an empty element")
rhs <- model.matrix(formula, rhs.frame)
## get needed column indices
rhs_colnames <- colnames(rhs)
meanfd_col <- grep("mean_FD", rhs_colnames)
age_col <- grep("age", rhs_colnames)
sex_col <- grep("sex", rhs_colnames)
## center mean FD and age columns
rhs[,meanfd_col] <- scale(rhs[,meanfd_col], scale=F)
rhs[,age_col] <- scale(rhs[,age_col], scale=F)

# Create contrasts
cons <- matrix(0, 4, ncol(rhs))
cons[1,age_col] <- 1
cons[2,age_col] <- -1
cons[3,sex_col] <- 1
cons[4,sex_col] <- -1
colnames(cons) <- rhs_colnames
rownames(cons) <- c("age_pos", "age_neg", "sex_pos", "sex_neg")

# Save this shiz
write.table(rhs, file="subinfo/04_discovery_regressors.txt")
write.table(cons, file="subinfo/04_discovery_contrasts.txt")


###
# Replication Sample
###

# Read in model
model <- read.csv("subinfo/04_replication_df.csv")

# Setup formula
formula <- . ~ site + run + mean_FD + age + sex
formula[[2]] <- NULL

# Create regressors
rhs.frame <- model.frame(formula, model, drop.unused.levels = TRUE)
if (nrow(rhs.frame) != nrow(model))
    vstop("One of your factors has an empty element")
rhs <- model.matrix(formula, rhs.frame)
## get needed column indices
rhs_colnames <- colnames(rhs)
meanfd_col <- grep("mean_FD", rhs_colnames)
age_col <- grep("age", rhs_colnames)
sex_col <- grep("sex", rhs_colnames)
## center mean FD and age columns
rhs[,meanfd_col] <- scale(rhs[,meanfd_col], scale=F)
rhs[,age_col] <- scale(rhs[,age_col], scale=F)

# Create contrasts
cons <- matrix(0, 4, ncol(rhs))
cons[1,age_col] <- 1
cons[2,age_col] <- -1
cons[3,sex_col] <- 1
cons[4,sex_col] <- -1
colnames(cons) <- rhs_colnames
rownames(cons) <- c("age_pos", "age_neg", "sex_pos", "sex_neg")

# Save this shiz
write.table(rhs, file="subinfo/04_replication_regressors.txt")
write.table(cons, file="subinfo/04_replication_contrasts.txt")

