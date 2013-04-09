# This script plots the distribution of F-stats and p-values


###
# Setup
###

library(connectir)
library(ggplot2)

nobs <- 102

# Basics
odir <- "/home2/data/Projects/CWAS/age+gender/02_correction"
sdir <- "/home2/data/Projects/CWAS/age+gender/01_resolution/cwas/voxelwise"
mdir <- file.path(sdir, "age+gender_with-meanFD_50k_rhs_combined.mdmr")
factors <- c("age", "sex")
nfactors <- length(factors)

# Fstats
descs <- file.path(mdir, sprintf("fperms_%s.desc", factors))
list.Fperms <- lapply(descs, attach.big.matrix)
Fstats <- sapply(1:nfactors, function(i) list.Fperms[[i]][1,])
nvoxs <- nrow(Fstats)
rm(list.Fperms); invisible(gc(F,T))

# Pvals
pdesc <- file.path(mdir, "pvals.desc")
Pvals <- attach.big.matrix(pdesc)

# Data Frame
df <- data.frame(
    factors = rep(factors, each=nvoxs), 
    fstats = as.vector(Fstats), 
    pvals = as.vector(Pvals[,]), 
    log.pvals = -log10(as.vector(Pvals[,])), 
    z.pvals = qt(as.vector(Pvals[,]), nobs, lower.tail=F), 
    f.pvals = qf(as.vector(Pvals[,]), 1, nobs, lower.tail=F)
)


###
# Plot distribution of p-values
###

# Histogram of logp
x11(width=7, height=7)
ggplot(df, aes(x=log.pvals, fill=factors)) + 
       geom_histogram(binwidth=0.25) + 
       facet_grid(factors ~ .) + 
       xlab("-log10 p-values") + 
       ylab("# of Voxels") + 
       theme(axis.text = element_text(size=20), 
             axis.title = element_text(size=20), 
             strip.text = element_text(size=16), 
             legend.position = "none")
ggsave(file.path(odir, "10_hist_logp.png"))
dev.off()

# Histogram of t-stats
x11(width=7, height=7)
ggplot(df, aes(x=z.pvals, fill=factors)) + 
       geom_histogram(binwidth=0.1) + 
       facet_grid(factors ~ .) + 
       xlab("t-statistic") + 
       ylab("# of Voxels") + 
       theme(axis.text = element_text(size=20), 
             axis.title = element_text(size=20), 
             strip.text = element_text(size=16), 
             legend.position = "none")
ggsave(file.path(odir, "10_hist_tstats.png"))
dev.off()

# Histogram of f-stats
x11(width=7, height=7)
ggplot(df, aes(x=f.pvals, fill=factors)) + 
       geom_histogram(binwidth=0.5) + 
       facet_grid(factors ~ .) + 
       xlab("f-statistic") + 
       ylab("# of Voxels") + 
       theme(axis.text = element_text(size=20), 
             axis.title = element_text(size=20), 
             strip.text = element_text(size=16), 
             legend.position = "none")
ggsave(file.path(odir, "10_hist_fstats.png"))
dev.off()

# Histogram of pseudo-f
x11(width=7, height=7)
ggplot(df, aes(x=fstats, fill=factors)) + 
       geom_histogram(binwidth=0.2) + 
       facet_grid(factors ~ .) + 
       xlab("pseudo-f statistic") + 
       ylab("# of Voxels") + 
       theme(axis.text = element_text(size=20), 
             axis.title = element_text(size=20), 
             strip.text = element_text(size=16), 
             legend.position = "none")
ggsave(file.path(odir, "10_hist_pseudof.png"))
dev.off()

# Test normality for logp
x11(width=12, height=6)
par(mfrow=c(1,2))
## age
fac <- factors[1]
x <- df$log.pvals[df$factors==fac]
qqnorm(x, main="Age (logp)")
qqline(x, col=2)
## gender
fac <- factors[2]
x <- df$log.pvals[df$factors==fac]
qqnorm(x, main="Gender (logp)")
qqline(x, col=2)
## save
dev.copy(png, '11_qq_logp.png', width=1200, height=600)
dev.off(); dev.off()

# Test normality for tstats
x11(width=12, height=6)
par(mfrow=c(1,2))
## age
fac <- factors[1]
x <- df$z.pvals[df$factors==fac]
qqnorm(x, main="Age (tstat)")
qqline(x, col=2)
## gender
fac <- factors[2]
x <- df$z.pvals[df$factors==fac]
qqnorm(x, main="Gender (tstat)")
qqline(x, col=2)
## save
dev.copy(png, '11_qq_tstats.png', width=1200, height=600)
dev.off(); dev.off()

# Test normality for fstats
x11(width=12, height=6)
par(mfrow=c(1,2))
## age
fac <- factors[1]
x <- df$z.pvals[df$factors==fac]
qqnorm(x, main="Age (fstat)")
qqline(x, col=2)
## gender
fac <- factors[2]
x <- df$z.pvals[df$factors==fac]
qqnorm(x, main="Gender (fstat)")
qqline(x, col=2)
## save
dev.copy(png, '11_qq_fstats.png', width=1200, height=600)
dev.off(); dev.off()

# Comparison of logp vs fstats
x11(width=7, height=7)
ggplot(df, aes(x=log.pvals, y=fstats, group=factors)) +
    geom_point(aes(color=factors), alpha=I(0.4), size=I(4)) + 
    geom_smooth(method=lm) + 
    facet_grid(factors ~ .) + 
    xlab("-log10 p-values") + 
    ylab("Pseudo-F Statistic") + 
    theme(axis.text = element_text(size=20), 
          axis.title = element_text(size=20), 
          strip.text = element_text(size=16), 
          legend.position = "none")
ggsave("12_compare_fstats_vs_logp.png")
dev.off()

# Comparison of tstats vs fstats
x11(width=7, height=7)
ggplot(df, aes(x=z.pvals, y=fstats, group=factors)) +
    geom_point(aes(color=factors), alpha=I(0.4), size=I(4)) + 
    geom_smooth(method=lm) + 
    facet_grid(factors ~ .) + 
    xlab("t-Statistic") + 
    ylab("Pseudo-F Statistic") + 
    theme(axis.text = element_text(size=20), 
          axis.title = element_text(size=20), 
          strip.text = element_text(size=16), 
          legend.position = "none")
ggsave("12_compare_fstats_vs_tstats.png")
dev.off()

# Comparison of fstats vs fstats
x11(width=7, height=7)
ggplot(df, aes(x=f.pvals, y=fstats, group=factors)) +
    geom_point(aes(color=factors), alpha=I(0.4), size=I(4)) + 
    geom_smooth(method=lm) + 
    facet_grid(factors ~ .) + 
    xlab("F-Statistic") + 
    ylab("Pseudo-F Statistic") + 
    theme(axis.text = element_text(size=20), 
          axis.title = element_text(size=20), 
          strip.text = element_text(size=16), 
          legend.position = "none")
ggsave("12_compare_fstats_vs_fstats.png")
dev.off()



###
# Number of permutations needed to be complete
###

ndf <- ddply(df, .(factors), function(sdf) {
    w <- sdf$log.pvals == max(sdf$log.pvals)
    top.pseudof <- quantile(sdf$fstats[w], seq(0.75,1,by=0.05))
    
    # log.pvals
    model <- lm(log.pvals ~ fstats, sdf)
    top.logpvals <- predict(model, data.frame(fstats=top.pseudof))
    
    # fstats
    model <- lm(f.pvals ~ fstats, sdf)
    top.fstats <- predict(model, data.frame(fstats=top.pseudof))
    
    data.frame(
        factor = rep(sdf$factors[1], length(top.fstats)),
        pseudo.fstats = top.pseudof, 
        log.pvals = top.logpvals, 
        f.pvals = top.fstats
    )
})
