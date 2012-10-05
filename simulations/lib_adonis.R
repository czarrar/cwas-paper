# modified version of adonis function in vegan
adonis.alt <- function (formula, data = NULL, permutations = 999, method = "bray", 
    strata = NULL, contr.unordered = "contr.sum", contr.ordered = "contr.poly", 
    ...) 
{
    TOL <- 1e-07
    Terms <- terms(formula, data = data)
    lhs <- formula[[2]]
    lhs <- eval(lhs, data, parent.frame())
    formula[[2]] <- NULL
    rhs.frame <- model.frame(formula, data, drop.unused.levels = TRUE)
    op.c <- options()$contrasts
    options(contrasts = c(contr.unordered, contr.ordered))
    rhs <- model.matrix(formula, rhs.frame)
    options(contrasts = op.c)
    grps <- attr(rhs, "assign")
    qrhs <- qr(rhs)
    rhs <- rhs[, qrhs$pivot, drop = FALSE]
    rhs <- rhs[, 1:qrhs$rank, drop = FALSE]
    grps <- grps[qrhs$pivot][1:qrhs$rank]
    u.grps <- unique(grps)
    nterms <- length(u.grps) - 1
    
    if (inherits(lhs, "dist")) 
        dmat <- as.matrix(lhs^2)
    else {
        dist.lhs <- as.matrix(vegdist(lhs, method = method, ...))
        dmat <- dist.lhs^2
    }
    n <- nrow(dmat)
    I <- diag(n)
    ones <- matrix(1, nrow = n)
    A <- -(dmat)/2
    # G <- -0.5 * A %*% (I - ones %*% t(ones)/n) # old
    G <- (I - ones %*% t(ones)/n) %*% A %*% (I - ones %*% t(ones)/n) # new
    
    qrX <- qr(rhs, tol=TOL)				# new
    Q <- qr.Q(qrX)						# new
    H  <- tcrossprod(Q[,1:qrX$rank])	# new
    H.snterm <- H						# new
    # H.snterm <- H.s[[nterms]]			# old (appeared later)
    
    H.s <- lapply(2:length(u.grps), function(j) {
        #Xj <- rhs[, grps %in% u.grps[1:j]] # old
        Xj <- rhs[, grps %in% u.grps[-j]]	# new
        qrX <- qr(Xj, tol = TOL)
        Q <- qr.Q(qrX)
        # tcrossprod(Q[, 1:qrX$rank])		# old
        H - tcrossprod(Q[, 1:qrX$rank])		# new
    })
    #if (length(H.s) > 1) # old
    #    for (i in length(H.s):2) H.s[[i]] <- H.s[[i]] - H.s[[i - # old
    #        1]] # old
    
    SS.Exp.comb <- sapply(H.s, function(hat) sum(G * t(hat)))
    #SS.Exp.each <- c(SS.Exp.comb - c(0, SS.Exp.comb[-nterms])) # old
    SS.Exp.each <- SS.Exp.comb  # new
    
    SS.Res <- sum(G * t(I - H.snterm))
    df.Exp <- sapply(u.grps[-1], function(i) sum(grps == i))
    df.Res <- n - qrhs$rank
    if (inherits(lhs, "dist")) {
        beta.sites <- qr.coef(qrhs, as.matrix(lhs))
        beta.spp <- NULL
    }
    else {
        beta.sites <- qr.coef(qrhs, dist.lhs)
        beta.spp <- qr.coef(qrhs, as.matrix(lhs))
    }
    colnames(beta.spp) <- colnames(lhs)
    colnames(beta.sites) <- rownames(lhs)
    F.Mod <- (SS.Exp.each/df.Exp)/(SS.Res/df.Res)
    f.test <- function(H, G, I, df.Exp, df.Res, H.snterm) {
        (sum(G * t(H))/df.Exp)/(sum(G * t(I - H.snterm))/df.Res)
    }
    SS.perms <- function(H, G, I) {
        c(SS.Exp.p = sum(G * t(H)), S.Res.p = sum(G * t(I - H)))
    }
    if (missing(strata)) 
        strata <- NULL
    p <- sapply(1:permutations, function(x) permuted.index(n, 
        strata = strata))
    f.perms <- sapply(1:nterms, function(i) {
        sapply(1:permutations, function(j) {
            f.test(H.s[[i]], G[p[, j], p[, j]], I, df.Exp[i], 
                df.Res, H.snterm)
        })
    })
    f.perms <- round(f.perms, 12)
    F.Mod <- round(F.Mod, 12)
    SumsOfSqs = c(SS.Exp.each, SS.Res, sum(SS.Exp.each) + SS.Res)
    tab <- data.frame(Df = c(df.Exp, df.Res, n - 1), SumsOfSqs = SumsOfSqs, 
        MeanSqs = c(SS.Exp.each/df.Exp, SS.Res/df.Res, NA), F.Model = c(F.Mod, 
            NA, NA), R2 = SumsOfSqs/SumsOfSqs[length(SumsOfSqs)], 
        P = c((rowSums(t(f.perms) >= F.Mod) + 1)/(permutations + 
            1), NA, NA))
    rownames(tab) <- c(attr(attr(rhs.frame, "terms"), "term.labels")[u.grps], 
        "Residuals", "Total")
    colnames(tab)[ncol(tab)] <- "Pr(>F)"
    class(tab) <- c("anova", class(tab))
    out <- list(aov.tab = tab, call = match.call(), coefficients = beta.spp, 
        coef.sites = beta.sites, f.perms = f.perms, model.matrix = rhs, 
        terms = Terms, G=G, IH=H.snterm, H.s=H.s)
    class(out) <- "adonis"
    out
}

# Original adonis with minor fix to G being computed using A and not dmat
adonis.orig <- function (formula, data = NULL, permutations = 999, method = "bray", 
    strata = NULL, contr.unordered = "contr.sum", contr.ordered = "contr.poly", 
    ...) 
{
    TOL <- 1e-07
    Terms <- terms(formula, data = data)
    lhs <- formula[[2]]
    lhs <- eval(lhs, data, parent.frame())
    formula[[2]] <- NULL
    rhs.frame <- model.frame(formula, data, drop.unused.levels = TRUE)
    op.c <- options()$contrasts
    options(contrasts = c(contr.unordered, contr.ordered))
    rhs <- model.matrix(formula, rhs.frame)
    options(contrasts = op.c)
    grps <- attr(rhs, "assign")
    qrhs <- qr(rhs)
    rhs <- rhs[, qrhs$pivot, drop = FALSE]
    rhs <- rhs[, 1:qrhs$rank, drop = FALSE]
    grps <- grps[qrhs$pivot][1:qrhs$rank]
    u.grps <- unique(grps)
    nterms <- length(u.grps) - 1
    H.s <- lapply(2:length(u.grps), function(j) {
        Xj <- rhs[, grps %in% u.grps[1:j]]
        qrX <- qr(Xj, tol = TOL)
        Q <- qr.Q(qrX)
        tcrossprod(Q[, 1:qrX$rank])
    })
    if (inherits(lhs, "dist")) 
        dmat <- as.matrix(lhs^2)
    else {
        dist.lhs <- as.matrix(vegdist(lhs, method = method, ...))
        dmat <- dist.lhs^2
    }
    n <- nrow(dmat)
    I <- diag(n)
    ones <- matrix(1, nrow = n)
    A <- -(dmat)/2
    # G <- -0.5 * dmat %*% (I - ones %*% t(ones)/n)
    G <- (I - ones %*% t(ones)/n) %*% A %*% (I - ones %*% t(ones)/n)
    SS.Exp.comb <- sapply(H.s, function(hat) sum(G * t(hat)))
    SS.Exp.each <- c(SS.Exp.comb - c(0, SS.Exp.comb[-nterms]))
    H.snterm <- H.s[[nterms]]
    if (length(H.s) > 1) 
        for (i in length(H.s):2) H.s[[i]] <- H.s[[i]] - H.s[[i - 
            1]]
    SS.Res <- sum(G * t(I - H.snterm))
    df.Exp <- sapply(u.grps[-1], function(i) sum(grps == i))
    df.Res <- n - qrhs$rank
    if (inherits(lhs, "dist")) {
        beta.sites <- qr.coef(qrhs, as.matrix(lhs))
        beta.spp <- NULL
    }
    else {
        beta.sites <- qr.coef(qrhs, dist.lhs)
        beta.spp <- qr.coef(qrhs, as.matrix(lhs))
    }
    colnames(beta.spp) <- colnames(lhs)
    colnames(beta.sites) <- rownames(lhs)
    F.Mod <- (SS.Exp.each/df.Exp)/(SS.Res/df.Res)
    f.test <- function(H, G, I, df.Exp, df.Res, H.snterm) {
        (sum(G * t(H))/df.Exp)/(sum(G * t(I - H.snterm))/df.Res)
    }
    SS.perms <- function(H, G, I) {
        c(SS.Exp.p = sum(G * t(H)), S.Res.p = sum(G * t(I - H)))
    }
    if (missing(strata)) 
        strata <- NULL
    p <- sapply(1:permutations, function(x) permuted.index(n, 
        strata = strata))
    f.perms <- sapply(1:nterms, function(i) {
        sapply(1:permutations, function(j) {
            f.test(H.s[[i]], G[p[, j], p[, j]], I, df.Exp[i], 
                df.Res, H.snterm)
        })
    })
    f.perms <- round(f.perms, 12)
    F.Mod <- round(F.Mod, 12)
    SumsOfSqs = c(SS.Exp.each, SS.Res, sum(SS.Exp.each) + SS.Res)
    tab <- data.frame(Df = c(df.Exp, df.Res, n - 1), SumsOfSqs = SumsOfSqs, 
        MeanSqs = c(SS.Exp.each/df.Exp, SS.Res/df.Res, NA), F.Model = c(F.Mod, 
            NA, NA), R2 = SumsOfSqs/SumsOfSqs[length(SumsOfSqs)], 
        P = c((rowSums(t(f.perms) >= F.Mod) + 1)/(permutations + 
            1), NA, NA))
    rownames(tab) <- c(attr(attr(rhs.frame, "terms"), "term.labels")[u.grps], 
        "Residuals", "Total")
    colnames(tab)[ncol(tab)] <- "Pr(>F)"
    class(tab) <- c("anova", class(tab))
    out <- list(aov.tab = tab, call = match.call(), coefficients = beta.spp, 
        coef.sites = beta.sites, f.perms = f.perms, model.matrix = rhs, 
        terms = Terms, G=G, IH=H.snterm, H.s=H.s)
    class(out) <- "adonis"
    out
}
