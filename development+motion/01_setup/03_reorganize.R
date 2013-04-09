library(plyr)

df <- read.csv("../subinfo/00_subjectInfo.csv")

###
# Get list of 1st mprage and 1st functional
# + other demographic info
###

in_basedir <- "/data/Originals/POWER_2012"
out_basedir <- "/home2/data/Projects/CWAS/development+motion/Originals"
## Need subject IDs
df$subid <- sub("/session.*", "", df$NITRC.identifier)
## Constrain to unique IDs
sdf <- df[!duplicated(df$subid),]
## Fix
sdf$TR[is.na(sdf$TR)] <- 2.5
sdf$X..frames.run <- 133
## Convert TR to scan id
tr_to_scanid <- data.frame(
    tr = unique(sdf$TR), 
    num = 1:length(unique(sdf$TR))
)
## Glob the session and Glob the mprage_1 and rest_1
newdf <- ddply(sdf, .(subid), function(line) {
    # paths
    session <- file.path(in_basedir, 
        sprintf("cohort%i", line$Power.NeuroImage.cohort), 
        line$subid, 
        "session_*"
    )
    mprage_star <- file.path(session, "mprage_*", "mprage.nii.gz")
    rest_star <- file.path(session, "rest_*", "rest.nii.gz")
    
    # glob
    mprage <- Sys.glob(mprage_star)
    rest <- Sys.glob(rest_star)
    
    # choose one input
    in_mprage <- mprage[1]
    in_rest <- rest[1]
    
    # what's the corresponding output
    siteid <- sprintf("tr_%i", tr_to_scanid$num[tr_to_scanid$tr==line$TR])
    out_dir <- file.path(out_basedir, siteid, line$subid)
    out_mprage <- file.path(out_dir, "mprage.nii.gz")
    out_rest <- file.path(out_dir, "rest.nii.gz")
    
    # return
    c(
        id = line$subid, 
        cohort = line$Power.NeuroImage.cohort, 
        instructions = ifelse(line$data.type == "fixation", "fixation", "none"), 
        sex = ifelse(line$gender.M.or.female == "M", "M", "F"), 
        age = line$age, 
        time.points = line$X..frames.run, 
        tr = line$TR, 
        in_mprage = in_mprage, 
        in_rest = in_rest, 
        out_dir = out_dir, 
        out_mprage = out_mprage, 
        out_rest = out_rest
    )
})


###
# Soft link originals into new directory
###

vcat <- function(...) cat(sprintf(...), "\n")

d_ply(newdf, .(subid), function(line) {
    vcat("Subject: %s", line$subid)
    dir.create(line$out_dir, recursive=TRUE)
    file.symlink(line$in_mprage, line$out_mprage)
    file.symlink(line$in_rest, line$out_rest)
})


###
# Save
###

newdf2 <- subset(newdf, select=c("id", "cohort", "sex", "age", "time.points", "tr"))
write.csv(newdf2, file="../subinfo/01_subject_info.csv")
