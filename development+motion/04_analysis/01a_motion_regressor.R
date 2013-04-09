# This will create a regressor file with mean FD

df <- read.csv("../subinfo/02_details.csv")
df <- df["mean_FD"]

f <- . ~ mean_FD
f[[2]] <- NULL

df$mean_FD <- scale(df$mean_FD, scale=FALSE)
rhs.frame <- model.frame(f, df, drop.unused.levels=T)
rhs <- model.matrix(f, rhs.frame)
rmat <- rhs[,]

write.table(rmat, file="../subinfo/02_motion_regressor.txt", row.names=F)
