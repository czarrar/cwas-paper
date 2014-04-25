source("lib_mdmr.R")

verbose <- TRUE
text_progress <- "text"

read_func_data <- function(paths) {
    llply(paths, read.nifti.image, .progress=text_progress)
}

compute_connectivity <- function(funcs) {
    laply(funcs, cor, .progress=text_progress)
}

# In this script, we want to generate a matrix of group differences
create_group_differences <- function(n_nodes, diff_direction, effect_size, conn_per_node) {
    # Start with no group differences
    mat <- matrix(0, n_nodes, n_nodes)
    
    # Select half the nodes to change
    n_nodes_change <- floor(n_nodes/2)
    node_inds <- sample(1:n_nodes, n_nodes_change)
    
    # Generate the group differences
    # vary them by 20% of the effect size
    grp_diffs <- rnorm(n_nodes_change * conn_per_node, mean=effect_size, sd=effect_size*0.20)            
    grp_diffs <- matrix(grp_diffs, conn_per_node, n_nodes_change)
    
    # If two direction effect, then flip half of the differences
    if (diff_direction == "two") {
        for (i in 1:n_nodes_change) {
            conn_inds <- sample(1:conn_per_node, round(conn_per_node/2))
            grp_diffs[conn_inds,i] <- -1 * grp_diffs[conn_inds,i]
        }
    }
    
    # Add on the differences
    for (i in 1:n_nodes_change) {
        node_ind <- node_inds[i]
        
        # Select the connections to change
        conn_inds <- sample(1:n_nodes, conn_per_node)
        
        # Add on the differences
        mat[conn_inds,node_ind] <- mat[conn_inds,node_ind] + grp_diffs[,i]
    }
    
    return(mat)
}

# GOAL: Randomly select the desired sample size and add group variable
select_subjects <- function(sample_size, df) {
    # Filter
    inds <- sample(df$X, sample_size)
    sdf  <- df[inds,]
    
    # Grouping Variables
    sdf$group <- factor(rep(c("A", "B"), length.out=sample_size))
            
    return(sdf)
}

# GOAL: Add differences to each subject based on group differences 
# for each subject, we will add a bit of variability 
# take each difference and give it a variability of 20%
add_subject_differences <- function(grp_diff_mat, conn_data, df) {        
    n_nodes    <- nrow(grp_diff_mat)
    groupB     <- df$group == "B"
    n_groupB   <- sum(groupB)
    
    diff_inds  <- which(grp_diff_mat!=0)
    coords     <- expand.grid(list(i=1:n_nodes, j=1:n_nodes))
    
    pb <- create_progress_bar(text_progress)
    pb$init(length(diff_inds))
    for (ind in diff_inds) {
        i <- coords[ind,]$i
        j <- coords[ind,]$j
        subj_diffs <- rnorm(n_groupB, mean=grp_diff_mat[i,j], sd=grp_diff_mat[i,j]*0.2)
        conn_data[groupB,i,j] <- conn_data[groupB,i,j] + subj_diffs
        pb$step()
    }
    pb$term()
    
    return(conn_data)
}

## For a subject:
## - normalize each column
## - compute the mean global signal
## - compute the correlation between global signal and rest of brain
## - compute mean of prior correlations
#compute_mean_global_connectivity <- function(ts_data) {
#    norm_cols <- function(X) {
#        Xc <- sweep(X, 2, colMeans(X))
#        Xd <- sweep(Xc, 2, sqrt(colSums(Xc^2)), "/")
#        return(Xd)
#    }
#    
#    ts_data_n   <- norm_cols(ts_data)
#    mean_ts     <- rowMeans(ts_data_n)
#    gcors       <- mean_ts %*% ts_data_n
#    mean_gcor   <- mean(gcors)
#    
#    return(mean_gcor)
#}

regress_out_nuisance <- function(conn_data, select_df, inc_mean_global) {
    resid_data <- array(0, dim(conn_data))
    nrois <- dim(conn_data)[2]
    
    pb <- create_progress_bar(text_progress)
    pb$init(nrois)
    for (i in 1:nrois) {
        # Multiple regression on all connections from seed ROI to all other ROIs
        conn_mat <- conn_data[,i,]
        
        # Regression formula
        # include or not include mean global connectivity as a regressor
        # regress out any and all effects (except the artificial group differences)
        if (inc_mean_global == "no") {
            form <- conn_mat ~ site + mean_FD + age + sex
        } else {
            form <- conn_mat ~ site + mean_FD + age + sex + mean_global
        }
            
        # Run regression
        model <- lm(form, select_df)
    
        ## So I had included the line below these comments
        ## but by including the mean it artificially inflates the values in the other group
        # resid_data[,i,] <- sweep(model$residuals, 2, colMeans(conn_mat), "+")
    
        # Save the residuals (with mean across subjects)
        resid_data[,i,] <- sweep(model$residuals, 2, model$coefficients[1,], "+")
        #resid_data[,i,] <- model$residuals
    
        pb$step()
    }
    pb$term()
    
    return(resid_data)
}

compute_anova.group <- function(resid_data, select_df) {
    pb <- create_progress_bar(text_progress)
    pb$init(dim(resid_data)[3])
    aov_pvals <- apply(resid_data, 3, function(x) {
        res   <- summary(aov(x ~ group, select_df))
        pvals <- as.numeric(sapply(res, function(tab) tab$Pr[1]))
        pb$step()
        pvals
    })
    pb$term()
    return(aov_pvals)
}

compute_global.group <- function(resid_data, select_df) {
    deg <- t(apply(resid_data, 1, colMeans))
    res <- summary(aov(deg ~ group, select_df))
    deg_pvals <- as.numeric(sapply(res, function(tab) tab$Pr[1]))
    return(deg_pvals)
}

compute_mdmr.group <- function(resid_data, select_df) {
    vcat(verbose, "...distances")
    distances <- apply(resid_data, 3, function(x) {
        as.vector(1-cor(t(x)))
    })
    res <- local_mdmr(. ~ group, distances, select_df, nperms=4999)
    mdmr_pvals <- sapply(res$aov.tab, function(tab) tab$Pr[1])
    return(mdmr_pvals)
}

# Generates a contingency table or confusion matrix as a vector
summarize_significance <- function(ref_mat, dat) {
    ref_diff <- abs(ref_mat) > 0
    if (length(dim(dat)) == 0)
        ref_diff <- colSums(ref_diff) > 0
    dat_diff   <- dat<0.05
    
    tab <- table(factor(ref_diff, c(T,F)), factor(dat_diff, c(T,F)))
    vec <- as.vector(tab)
    names(vec) <- c("true.pos", "false.pos", 
                    "false.neg", "true.neg")
    
    return(vec)
}

# See wiki article on ROC...has some good stuff
# TPR = TP / (TP + FP)  # also sensitivity
# FPR = FP / (FP + TN)
# TNR = TN / (FP + TN)  # also specificity and is 1 - FPR
confusion_derivations <- function(confusions) {
    cm <- as.list(confusions)   # cm meaning confusion matrix
    
    tpr <- cm$true.pos / (cm$true.pos + cm$false.pos)
    fpr <- cm$false.pos / (cm$false.pos + cm$true.neg)
    tnr <- cm$true.neg / (cm$false.pos + cm$true.neg)
    if (tnr != (1-fpr)) stop("tnr != (1-fpr)")
    
    ret <- list(
        tpr = tpr, 
        fpr = fpr, 
        tnr = tnr, 
        sensitivity = tpr, 
        specificity = tnr
    )
    
    return(ret)
}

compile_summaries <- function(...) {
    df <- cbind(methods=c("sca", "global", "mdmr"), rbind(...))
    as.data.frame(df)
}
