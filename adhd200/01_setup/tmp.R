# Groups matched for age, sex, and IQ within each site
## first split by site and gender
newdf2 <- ddply(newdf, .(site, gender), function(sdf) {
    sdf <- sdf[order(sdf$age, sdf$iq),]
    sdf.tdc <- subset(sdf, group=="TDC")
    sdf.adhd <- subset(sdf, group=="ADHD-C")
    n <- min(nrow(sdf.tdc), nrow(sdf.adhd))
    
    # Probably a more efficient to do this, then 2 for loops
    if (n == nrow(sdf.tdc)) {
        adhd.inds <- c()
        for (i in 1:n) {
            # get difference
            age.diff <- abs(sdf.tdc$age[i] - sdf.adhd$age)
            iq.diff <- abs(sdf.tdc$iq[i] - sdf.adhd$iq)
            # restrict age to be at least 1 year
            # and not have been used before
            w.age <- which(age.diff < 1)
            w.age <- w.age[!(w.age %in% adhd.inds)]
            if (length(w.age) == 0) {
                w.age <- 1:length(age.diff)
                w.age <- w.age[!(w.age %in% adhd.inds)]
            }
            # minimize age and iq difference
            w.combined <- which.min((age.diff*10 + iq.diff)[w.age])
            # save
            adhd.inds <- c(adhd.inds, w.age[w.combined])
        }
        sdf.tdc2 <- sdf.tdc
        sdf.adhd2 <- sdf.adhd[adhd.inds,]
    } else {
        tdc.inds <- c()
        for (i in 1:n) {
            # get difference
            age.diff <- abs(sdf.adhd$age[i] - sdf.tdc$age)
            iq.diff <- abs(sdf.adhd$iq[i] - sdf.tdc$iq)
            # restrict age to be at least 1 year
            # and not have been used before
            w.age <- which(age.diff < 1)
            w.age <- w.age[!(w.age %in% tdc.inds)]
            if (length(w.age) == 0) {
                w.age <- 1:length(age.diff)
                w.age <- w.age[!(w.age %in% tdc.inds)]
            }
            # minimize age and iq difference
            w.combined <- which.min((age.diff*10 + iq.diff)[w.age])
            # save
            tdc.inds <- c(tdc.inds, w.age[w.combined])
        }
        sdf.tdc2 <- sdf.tdc[tdc.inds,]
        sdf.adhd2 <- sdf.adhd
    }
    
    rbind(sdf.tdc2, sdf.adhd2)
})

# SAVE
write.csv(newdf2, file="../subinfo/02_subject_info.csv")
