anova_performance <- function(subjects.wt, df, conns, settings) {
    vcat(settings$verbose, "Running ANOVA on every connection")
    
    # nnodes x nnodes
    aov.pvals <- aaply(subjects.wt, 2, function(x) {
        res <- summary(aov(t(x) ~ group, df))
        pvals <- as.numeric(sapply(res, function(tab) tab$Pr[1]))
        pvals
    }, .progress="text", .parallel=settings$parallel)
    aov.pvals <- t(aov.pvals)   # make output like apply

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

degree_centrality_performance <- function(subjects.wt, df, conns, settings) {
    vcat(settings$verbose, "Running degree centrality on every node")

    deg <- aaply(subjects.wt, 2, colMeans, .progress="text", .parallel=settings$parallel)
    deg <- t(deg)   # make output like apply
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
    distances <- aaply(subjects.wt, 2, function(x) {
        as.vector(zdist(x))
    }, .progress="text", .parallel=settings$parallel)
    distances <- t(distances)   # make output like apply
    names(dim(distances)) <- c("subjects^2", "nodes")
    dimnames(distances) <- dimnames(list(subject.squared=1:settings$nsubs^2, node=1:settings$nnode))
    distances
}

mdmr_performance <- function(distances, df, nodes, settings) {
    vcat(settings$verbose, "Running MDMR on every node")
    
    res <- mdmr(. ~ group, distances, df)
    mdmr.pvals <- sapply(res$aov.tab, function(tab) tab$Pr[1])

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

#kmeans_performance <- function(distances, df, nodes, settings) {
#    vcat(settings$verbose, "Running K-Means on every node")
#    
#    u.grp <- sort(unique(df$group))
#    ref.members <- as.numeric(df$group)
#    k <- length(unique(df$group))
#    n <- nrow(df)
#    
#    cluster_memberships <- aaply(distances, 2, function(dvec) {
#        dmat <- matrix(dvec, n, n)
#        members <- kmeans(dmat, k, iter.max=200, nstart=20, algorithm="Hartigan-Wong")$cluster
#        match_cluster_memberships(ref.members, members)
#    }, .progress="text", .parallel=settings$parallel)
#    cluster_memberships <- t(cluster_memberships)   # make output like apply
#    names(dim(cluster_memberships)) <- c("subjects", "nodes")
#    dimnames(cluster_memberships) <- dimnames(list(subject=1:settings$nsubs, node=1:settings$nnode))
#    
#    res <- laply(1:settings$nnode, function(ni) {
#        tab <- table(df$group, cluster_memberships[,ni])
#        sum(diag(prop.table(tab)))
#        #kmeans.sensitivity <- tab[u.grp=="A",u.grp=="A"]/sum(tab[u.grp=="A",])
#        #kmeans.specificity <- tab[u.grp=="B",u.grp=="B"]/sum(tab[u.grp=="B",])
#        #c(kmeans.sensitivity, kmeans.specificity)
#    }, .progress="text", .parallel=settings$parallel)
#    
#    # todo: need to compare above to permuted group memberships
#    
#    list(
#        memberships=cluster_memberships,
#        res=res, 
#        sensitivity=mean(res[,1]), 
#        specificity=mean(res[,2])
#    )
#}
