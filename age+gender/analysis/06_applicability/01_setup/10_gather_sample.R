# This script will gather even age ranges from the complete sample

library(plyr)

basedir <- "/home/data/Projects/CWAS"
main.subdir <- file.path(basedir, "share/age+gender/subinfo")

df <- read.csv(file.path(main.subdir, "04_all_df.csv"))

new_df <- dlply(df, .(site, sex), function(sdf) {
    cat(sprintf("Site: %s and Sex: %s\n", sdf$site[1], sdf$sex[1]))
    sdf <- sdf[order(sdf$age),]
    n <- nrow(sdf)
    if (n == 1)
        return(data.frame())
    if (n %% 2) {
        is <- sample(1:n, n-1)
        sdf <- sdf[is,]
        n <- n-1
    }
    labels <- c("Discovery Sample", "Replication Sample")
    sdf$sample <- rep(sample(labels), length.out=n)
    for (i in seq(1,n,by=2)) {
        if (n < (i+1)) next
        sdf$sample[i:(i+1)] <- sample(sdf$sample[i:(i+1)])
    }
    sdf
})

new_func <- file.path(new_df$outdir, 
                      "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz")






write.csv(new_df, file=file.path(basedir, "04_all_df.csv"), row.names=F)
write.table(new_func, file=file.path(basedir, "04_all_funcpaths.txt"), 
            row.names=F, col.names=F)

