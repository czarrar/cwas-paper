#!/usr/bin/env Rscript

# This script converts the INDI IDs in the 10_raw.csv to match
# with those from coins and used in the preprocessing
# ^01 => M109

df <- read.csv("../subinfo/10_raw.csv")
df$Id <- sub("^1", "M109", df$Id)
write.csv(df, file="../subinfo/20_raw_coins_ids.csv", row.names=F)
