qr_for_mdmr <- function(X, TOL) {
    qrX <- qr(X, tol=TOL)
    Q <- qr.Q(qrX)
    Q[,1:qrX$rank]
}

# TODO: I had removed permutations that were correlated with model
permuted.index <- function (n, strata) {
    if (missing(strata) || is.null(strata)) 
        out <- sample(n, n)
    else {
        out <- 1:n
        inds <- names(table(strata))
        for (is in inds) {
            gr <- out[strata == is]
            if (length(gr) > 1)
                out[gr] <- sample(gr, length(gr))
        }
    }
    out
}

mdmr <- function(formula, many_dmats, predictors, nperms = 999, strata = NULL,  
                 contr.unordered = "contr.sum", contr.ordered = "contr.poly", 
                 hat.type = "relative", verbose=TRUE, run_parallel=FALSE)
{
    TOL <- 1e-07
    
    if (!is.matrix(many_dmats) || sqrt(nrow(many_dmats)) != nrow(predictors))
        stop("many_dmats must be a matrix of n^2 by t where n=# of obs/subj and t=# of tests")
    
    formula[[2]] <- NULL
    
    vcat(verbose, "...setting up design matrix")
    X.frame <- model.frame(formula, predictors, drop.unused.levels = TRUE)
    op.c <- options()$contrasts
    options(contrasts = c(contr.unordered, contr.ordered))
    X <- model.matrix(formula, X.frame)
    options(contrasts = op.c)
    grps <- attr(X, "assign")
    qrhs <- qr(X)
    X <- X[, qrhs$pivot, drop = FALSE]
    X <- X[, 1:qrhs$rank, drop = FALSE]
    
    # Factors
    vcat(verbose, "...setting up factors")
    grps    <- grps[qrhs$pivot][1:qrhs$rank]
    u.grps  <- unique(grps)
    nterms  <- length(u.grps) - 1
    
    vcat(verbose, "...setting other variables")
    nobs    <- nrow(predictors)
    ntests  <- ncol(many_dmats)
    I       <- diag(nobs)
    ones    <- matrix(1, nrow=nobs)
    
    vcat(verbose, "...creating H and IH")
    Q  <- qr_for_mdmr(X, TOL)
    H  <- tcrossprod(Q)
    IH <- I - H
    
    # Have one hat matrix for each factor
    vcat(verbose, "...creating hat matrices")
    if (hat.type == "relative") {
        many_H2s <- lapply(2:length(u.grps), function(j) {
            X_not_2 <- X[, grps %in% u.grps[-j]]
            Q_not_2 <- qr_for_mdmr(X_not_2, TOL)
            H_not_2 <- tcrossprod(Q_not_2)
            H2 <- H - H_not_2
            H2
        })
    } else if (hat.type == "sequential") {
        many_H2s <- lapply(2:length(u.grps), function(j) {
            Xj <- X[, grps %in% u.grps[1:j]]
            Qj <- qr_for_mdmr(Xj, TOL)
            Hj <- tcrossprod(Qj)
            Hj
        })
        for (j in length(many_H2s):2) {
            many_H2s[[j]] <- many_H2s[[j]] - many_H2s[[j-1]]
        }
    }
    
    vcat(verbose, "...setting degrees of freedom")
    df.Exp <- sapply(u.grps[-1], function(i) sum(grps == i))
    df.Res <- nobs - qrhs$rank
    
    vcat(verbose, "...creating permutation matrices")
    permat <- sapply(1:nperms, function(p) permuted.index(nobs, strata))
    permat <- cbind(1:nobs, permat)    # 1st permuatation is orignal data
    nperms  <- nperms + 1
    
    ###
    # Combine original and permuted matrices into one big matrix
    # NOTE: the original matrix is represented in the 1st 'permutation'
    ###
    
    vcat(verbose, "...creating gower's centered matrices")
    C <- I - ones %*% t(ones)/nobs
#    independent_Gs <- t(aaply(many_dmats, 2, function(x) {
    independent_Gs <- apply(many_dmats, 2, function(x) {
        dmat <- matrix(x, nobs, nobs)
        A <- -(dmat^2)/2
        G <- C %*% A %*% C
        as.vector(G)
    })
#    }, .progress="text", .parallel=run_parallel))
    names(dim(independent_Gs)) <- names(dim(many_dmats))
    dimnames(independent_Gs) <- dimnames(many_dmats)
    rm(many_dmats); gc()
    
    vcat(verbose, "...generating permuted H2s")
    many_permuted_H2s <- lapply(1:nterms, function(f) {
#        permuted_H2s <- t(laply(1:nperms, function(p) {
        permuted_H2s <- sapply(1:nperms, function(p) {
            as.vector(many_H2s[[f]][permat[,p],permat[,p]])
        })
#        }, .progress="text", .parallel=run_parallel))
        names(dim(permuted_H2s)) <- c("subjects^2", "permutations")
        dimnames(permuted_H2s) <- list(obs.squared=1:nobs^2, permutation=1:nperms)
        permuted_H2s
    })
    
    vcat(verbose, "...generating permuted IHs")
#    permuted_IHs <- t(laply(1:nperms, function(p) {
    permuted_IHs <- sapply(1:nperms, function(p) {
        as.vector(IH[permat[,p],permat[,p]])
    })
#    }, .progress="text", .parallel=run_parallel))
    names(dim(permuted_IHs)) <- c("subjects^2", "permutations")
    dimnames(permuted_IHs) <- list(obs.squared=1:nobs^2, permutation=1:nperms)
    
    vcat(verbose, "...calculating pseudo-F statistic")
#    many_permuted_and_indepenent_Fs <- llply(1:nterms, function(f) {
    many_permuted_and_indepenent_Fs <- lapply(1:nterms, function(f) {
        permuted_H2s <- many_permuted_H2s[[f]]
        MS.Exp <- crossprod(permuted_H2s, independent_Gs)/df.Exp[f]
        MS.Res <- crossprod(permuted_IHs, independent_Gs)/df.Res
        res <- MS.Exp/MS.Res   # this is num of perms x num of tests
        names(dim(res)) <- c("permutations", "tests")
        dimnames(res) <- list(permutation=1:nperms, test=1:ntests)
        res
    })
#    }, .progress="text", .parallel=run_parallel)
    
    # ntests x nfactors
    vcat(verbose, "...determining p-values")
    ps <- sapply(1:nterms, function(f) {
#        t(aaply(many_permuted_and_indepenent_Fs[[f]], 2, function(perm_Fs) {
        apply(many_permuted_and_indepenent_Fs[[f]], 2, function(perm_Fs) {
            # note: 1st F is from original non-permuted hat matrix
            sum(perm_Fs[1]<=perm_Fs)/nperms
        })
#        }, .progress="text", .parallel=run_parallel))
    })
    
    vcat(verbose, "...determining sum of squares")
    # ntests x nfactors
    SS.Exp <- sapply(1:nterms, function(f) {
        H2 <- many_permuted_H2s[[f]][,1]
        crossprod(H2, independent_Gs)
    })
    SS.Exp <- as.matrix(SS.Exp)
    # ntests
    SS.Res <- crossprod(as.vector(IH), independent_Gs)
    
    vcat(verbose, "...compiling output")
    out.tabs <- lapply(1:ntests, function(n) {
        tab <- data.frame(
            Df = c(df.Exp, df.Res, nobs-1), 
            SumsOfSqs = c(SS.Exp[n,], SS.Res[n], sum(SS.Exp[n,]) + SS.Res[n]), 
            MeanSqs = c(SS.Exp[n,]/df.Exp, SS.Res[n]/df.Res, NA), 
            F.Model = c((SS.Exp[n,]/df.Exp)/(SS.Res[n]/df.Res), NA, NA), 
            P = c(ps[n,], NA, NA)
        )
        colnames(tab)[ncol(tab)] <- "Pr(>F)"
        rownames(tab) <- c(attr(attr(X.frame, "terms"), "term.labels")[u.grps], 
            "Residuals", "Total")
        class(tab) <- c("anova", class(tab))
        tab
    })
    
    out <- list(
        aov.tab = out.tabs,
        call = match.call(), 
        f.perms = many_permuted_and_indepenent_Fs, 
        perms = permat, 
        model.matrix = X
    )
    class(out) <- "mdmr"
    
    out
}
