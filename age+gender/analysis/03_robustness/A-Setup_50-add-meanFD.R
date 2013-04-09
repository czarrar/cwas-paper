
library(plyr)


## DISCOVERY

df <- read.csv("subinfo/04_discovery_df.csv")

# framewise displacement files
fwd.files <- file.path(as.character(df$outdir), "parameters", "frame_wise_displacement.1D")

# mean FD
meanFD <- laply(fwd.files, function(f) {
    fwd <- as.numeric(read.table(f)[,1])
    mean(fwd)
}, .progress="text")
df$meanFD <- meanFD

# save
write.csv(df, file="subinfo/05_discovery_df.csv")


## REPLICATION

df <- read.csv("subinfo/04_replication_df.csv")

# framewise displacement files
fwd.files <- file.path(as.character(df$outdir), "parameters", "frame_wise_displacement.1D")

# mean FD
meanFD <- laply(fwd.files, function(f) {
    fwd <- as.numeric(read.table(f)[,1])
    mean(fwd)
}, .progress="text")
df$meanFD <- meanFD

# save
write.csv(df, file="subinfo/05_replication_df.csv")
