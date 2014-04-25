anova_performance <- function(subjects.wt, df, conns, settings) {
    vcat(settings$verbose, "Running ANOVA on every connection")
    
    # nnodes x nnodes
    #aov.pvals <- aaply(subjects.wt, 2, function(x) {
    aov.pvals <- apply(subjects.wt, 2, function(x) {
        res <- summary(aov(t(x) ~ group, df))
        pvals <- as.numeric(sapply(res, function(tab) tab$Pr[1]))
        pvals
    })
    #}, .progress="text", .parallel=settings$parallel)
    #aov.pvals <- t(aov.pvals)   # make output like apply

    # sensitivity => TP/(TP+FN)
    # specificity => TN/(TN+FP)
    aov.sensitivity <- mean(aov.pvals[conns$change]<settings$crit.pval)
    aov.specificity <- mean(aov.pvals[conns$nochange]>settings$crit.pval)
    
    list(
        pvals=aov.pvals,
        sensitivity=aov.sensitivity, 
        specificity=aov.specificity
    )
}

degree_centrality_performance <- function(subjects.wt, df, nodes, settings) {
    vcat(settings$verbose, "Running degree centrality on every node")

    #deg <- aaply(subjects.wt, 2, colMeans, .progress="text", .parallel=settings$parallel)
    deg <- apply(subjects.wt, 2, colMeans)
    #deg <- t(deg)   # make output like apply
    res <- summary(aov(deg ~ group, df))
    deg.pvals <- as.numeric(sapply(res, function(tab) tab$Pr[1]))

    # sensitivity => TP/(TP+FN)
    # specificity => TN/(TN+FP)
    deg.sensitivity <- mean(deg.pvals[nodes$change]<settings$crit.pval)
    deg.specificity <- mean(deg.pvals[nodes$nochange]>settings$crit.pval)
    
    list(
        pvals=deg.pvals, 
        sensitivity=deg.sensitivity,
        specificity=deg.specificity
    )
}

compute_distances <- function(subjects.wt, settings) {
    vcat(settings$verbose, "For each node, computing distances between subject connectivity maps")
#    distances <- aaply(subjects.wt, 2, function(x) {
    distances <- apply(subjects.wt, 2, function(x) {
        as.vector(zdist(x))
    })
#    }, .progress="text", .parallel=settings$parallel)
#    distances <- t(distances)   # make output like apply
    names(dim(distances)) <- c("subjects^2", "nodes")
    dimnames(distances) <- dimnames(list(subject.squared=1:settings$nsubs^2, node=1:settings$nnode))
    distances
}

mdmr_performance <- function(distances, df, nodes, settings) {
    vcat(settings$verbose, "Running MDMR on every node")
    
    # split up permutations
    if (nrow(df) > 250) {
        res1 <- mdmr(. ~ group, distances, df, nperms=2449)
        mdmr.pvals1 <- sapply(res1$aov.tab, function(tab) tab$Pr[1])
        rm(res1); gc()
        
        res2 <- mdmr(. ~ group, distances, df, nperms=2450)
        mdmr.pvals2 <- sapply(res2$aov.tab, function(tab) tab$Pr[1])
        rm(res2); gc()
        
        mdmr.pvals <- c(mdmr.pvals1, mdmr.pvals2[-1])
    } else {
        res <- mdmr(. ~ group, distances, df, nperms=4999)
        mdmr.pvals <- sapply(res$aov.tab, function(tab) tab$Pr[1])
    }
    
    # sensitivity => TP/(TP+FN)
    # specificity => TN/(TN+FP)
    mdmr.sensitivity <- mean(mdmr.pvals[nodes$change]<settings$crit.pval)
    mdmr.specificity <- mean(mdmr.pvals[nodes$nochange]>settings$crit.pval)

    list(
        pvals=mdmr.pvals,
        sensitivity=mdmr.sensitivity, 
        specificity=mdmr.specificity
    )
}
