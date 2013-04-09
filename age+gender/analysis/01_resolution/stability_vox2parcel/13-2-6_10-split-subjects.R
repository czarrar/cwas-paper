# This script splits the subjects into 10 overlapping groups 
# using the 10-fold cross validation approach

library(plyr)

base <- "/home2/data/Projects/CWAS/share/age+gender/analysis/01_resolution"
df <- read.csv(file.path(base, "z_details2.csv"))

setwd(file.path(base, "stability_parcel2vox"))

# Break up the subjects into 10 folds
nbreaks <- 10
df.folds <- ddply(df, .(sex), function(sdf) {
    cat(sprintf("Sex: %s\n", sdf$sex[1]))
    
    folds <- as.numeric(cut(sdf$age, nbreaks))
    sdf$folds <- folds
        
    sdf
})

# Create 10 lists of different combinations of subjects
for (i in 1:10) {
    whichsubs <- which(df.folds$folds != i)
    ofile <- sprintf("z_whichsubs_10fold_%02i.txt", i)
    write.table(whichsubs, file=ofile, quote=F, row.names=F, col.names=F)
}

