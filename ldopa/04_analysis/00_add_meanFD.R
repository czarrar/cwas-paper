library(plyr)

# Read in stuff
df <- read.csv("../subinfo/01_demo.csv")
funcpaths <- as.character(read.table("../subinfo/02_all_funcpaths.txt")[,1])

# Frame-wise displacement files
fwd.files <- file.path(dirname(dirname(dirname(funcpaths))), "parameters", "frame_wise_displacement.1D")

# mean FD
meanFD <- laply(fwd.files, function(f) {
    fwd <- as.numeric(read.table(f)[,1])
    mean(fwd)
}, .progress="text")
df$meanFD <- meanFD

# save
write.csv(df, file="../subinfo/02_demo.csv")
