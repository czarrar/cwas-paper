#!/usr/bin/env Rscript

# 1. Read in subject data
# 2. Compute connectivity for all possible connections
#    a. then vary selection of sample size
# 3. Add in the group effect randomly
#    a. only positive or half pos / half neg group differences
#    b. select N nodes and vary number of connections with that node with group difference
#    c. vary group difference (effect size) that added
# 4. Determine the mean global connectivity
# 5. Regress out the main effects including or not including the mean global connectivity
# 6. Run ANOVA, global, and MDMR

# We want to vary:
# - effect size
# - sample size
# - number of connections per node
# Do this with all positive differences and half positive and half negative.
# With 10 iterations?

suppressPackageStartupMessages(library(connectir))
library(plyr)
library(Rsge)

verbose <- TRUE
text_progress <- ifelse(verbose, "text", "none")

# NOTE: some functions use the verbose and text_progress global variables
#       so must call after them
source("x_functions.R")


###
# Read in subject data and paths
###

base <- "/home2/data/Projects/CWAS/share/simulations"
setwd(base)

df      <- read.csv("subinfo/10_subject_info.csv")
df$X    <- 1:nrow(df)

func_paths <- as.character(read.table("subinfo/12_rois0400_paths.txt")[,1])


###
# Factors to test
###

sample_sizes     <- c(24, 50, 100, 150, 200, 300, 400, 500)
effect_sizes     <- c(0.01, 0.02, 0.04, 0.08, 0.16, 0.32)
conns_per_node   <- c(2, 4, 8, 16, 32, 64, 128)
diff_directions  <- c("one", "two")
inc_mean_globals <- c("no", "yes")

opts <- expand.grid(list(
    diff_directions  = diff_directions, 
    effect_sizes     = effect_sizes, 
    conns_per_node   = conns_per_node, 
    sample_sizes     = sample_sizes, 
    inc_mean_globals = inc_mean_globals
))


###
# Parallel Processing Settings
###

nthreads <- 2
parallel_inds <- 1:nrow(opts)
#parallel_inds <- 1:4
njobs <- length(parallel_inds)
sge.options(sge.user.options = sprintf("-S /bin/bash -pe mpi %i", nthreads))


###
# Get the connectivity data (so hungry for them connections)
###

# Read in all the functional data
func_data <- read_func_data(func_paths)

# Compute connectivity for all possible connections
## nsubs x nrois x nrois
all_conn_data <- compute_connectivity(func_data)
nrois <- dim(all_conn_data)[2]


###
# Loop through all the permutations of the factors to test
###

# save the TP/FP/sensitivity/etc in a nice data frame

run_one_simulation <- function(ri) {
    source("/home2/data/Projects/CWAS/share/simulations/x_functions.R")
    
    blas_set_num_threads(nthreads)
    omp_set_num_threads(nthreads)
    
    # Settings for analysis
    row <- opts[ri,]
    diff_direction  <- as.character(row$diff_directions)
    effect_size     <- row$effect_sizes
    conn_per_node   <- row$conns_per_node
    sample_size     <- row$sample_sizes
    inc_mean_global <- as.character(row$inc_mean_globals)
    
    ###
    # Create the desired connectivity matrices
    # including simulated group differences
    ###
        
    # Create matrix with only group differences
    vcat(verbose, "Generate group differences with DIR=%s, ES=%.4f, CPN=%i", 
         diff_direction, effect_size, conn_per_node)
    grp_diff_mat <- create_group_differences(nrois, diff_direction, effect_size, 
                                             conn_per_node)
    
    # Filter the subject info for the desired sample size
    # note: this will also add the group variable!
    vcat(verbose, "Select sub-group of subjects for N=%i", sample_size)
    select_df   <- select_subjects(sample_size, df)
    
    # Filter the connectivity data for the desired sample size
    # and add the group differences to select participants in one group
    vcat(verbose, "Add subject differences for desired sub-group")
    conn_data   <- all_conn_data[select_df$X,,]
    conn_data   <- add_subject_differences(grp_diff_mat, conn_data, select_df)
    
    ## for testing
    # diff_data <- conn_data - all_conn_data[select_df$X,,]
    # tmp <- apply(diff_data, c(2,3), mean)
    # all.equal(as.numeric(which(colSums(tmp)>0)), which(colSums(grp_diff_mat)>0))
    
    
    ###
    # Noise covariate
    ###
    
    # Calculate the mean global connectivity
    vcat(verbose, "Calculating mean global connectivity")
    mean_globals <- apply(conn_data, 1, mean)
    select_df$mean_global <- mean_globals
    
    
    ###
    # Clean the data to create a pseudo-simulation
    ###
    
    vcat(verbose, "Cleaning up the data (regressing out shiz)")
    
    # Clean up baby
    resid_data <- regress_out_nuisance(conn_data, select_df, inc_mean_global)
    
    ## for testing
    # orig_conn_resid <- regress_out_nuisance(form, all_conn_data[select_df$X,,])
    # diff_data <- resid_data - orig_conn_resid
    # tmp <- apply(diff_data, c(2,3), mean)
    # all.equal(as.numeric(which(colSums(tmp)>0)), which(colSums(grp_diff_mat)>0))
    
    ## for extra testing
    # diff_data <- conn_data - all_conn_data[select_df$X,,]
    # orig_diff <- list()
    # orig_diff$all <- apply(diff_data, c(2,3), mean)
    # orig_diff$grpA <- apply(diff_data[select_df$group == "A",,], c(2,3), mean)
    # orig_diff$grpB <- apply(diff_data[select_df$group == "B",,], c(2,3), mean)
    #
    # orig_conn_resid <- regress_out_nuisance(all_conn_data[select_df$X,,])
    # diff_data <- resid_data - orig_conn_resid
    # resid_diff <- list()
    # resid_diff$all <- apply(diff_data, c(2,3), mean)
    # resid_diff$grpA <- apply(diff_data[select_df$group == "A",,], c(2,3), mean)
    # resid_diff$grpB <- apply(diff_data[select_df$group == "B",,], c(2,3), mean)
    
    
    ###
    # The meat of the analysis (what about the potatoes?)
    ###
        
    # Calculate our different measures
    vcat(verbose, "calculating connectionwise anova")
    anova_signif        <- compute_anova.group(resid_data, select_df)
    
    vcat(verbose, "calculating voxelwise global")
    global_signif       <- compute_global.group(resid_data, select_df)
    
    vcat(verbose, "calculating mdmr")
    mdmr_signif         <- compute_mdmr.group(resid_data, select_df)
    
    
    ###
    # Summarize
    ###
        
    # Gather the TP, TN, FP, FN
    anova_confusions    <- summarize_significance(grp_diff_mat, anova_signif)
    global_confusions   <- summarize_significance(grp_diff_mat, global_signif)
    mdmr_confusions     <- summarize_significance(grp_diff_mat, mdmr_signif)
    
    # Determine the sensitivity (TPR) and specificity (TNR or 1-FPR)
    anova_deriv         <- confusion_derivations(anova_confusions)
    global_deriv        <- confusion_derivations(global_confusions)
    mdmr_deriv          <- confusion_derivations(mdmr_confusions)
    
    
    ###
    # Save
    ###
    
    cur_summaries <- compile_summaries(anova_deriv, global_deriv, mdmr_deriv)
    
    cur_summaries$index             <- ri
    cur_summaries$diff_direction    <- diff_direction
    cur_summaries$effect_size       <- effect_size
    cur_summaries$conn_per_node     <- conn_per_node
    cur_summaries$sample_size       <- sample_size
    cur_summaries$mean_global       <- inc_mean_global
    
    cur_summaries <- cur_summaries[,c(7:ncol(cur_summaries),1:6)]
    
    return(cur_summaries)
}

savelist <- c("all_conn_data", "df", "nthreads", "verbose", "text_progress", "opts", "nrois")
res <- sge.parLapply(parallel_inds, run_one_simulation, 
                        njobs=njobs, trace=TRUE, debug=TRUE, 
                        function.savelist=savelist, 
                        packages=c("connectir", "plyr", "blasctl"))

# Goal is to have nice plots of:
# - ROC => TP vs FP
# - sensitivity => TP/(TP+FN)
# - specificity => TN/(TN+FP)
