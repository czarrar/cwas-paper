# Gather subject phenotypic data

## @knitr setup
library(plyr)
library(tools)

## @knitr gather-files
# for beijing only use session 1
# note: for ann arbor: line 16 or sub49687, the handedness was adjusted from L to B (for ambidextrous)
# nore: for vtech: I removed the first line that indicated the scan num associated with sleep status and incoporated it into the 2nd (now 1st) line
files = list(
    BeijingEOEC = "/home2/data/Originals/BeijingEOEC/BeijingEOEC_phenotypic.csv", 
    Berlin = "/home2/data/Originals/Berlin/Berlin_phenotypic.csv", 
    ann_arbor_a = "/home2/data/Originals/FCon1000/raw/ann_arbor_a/AnnArbor_a_demographics.txt", 
    baltimore = "/home2/data/Originals/FCon1000/raw/baltimore/Baltimore_demographics.txt", 
    bangor = "/home2/data/Originals/FCon1000/raw/bangor/Bangor_demographics.txt", 
    beijing = "/home2/data/Originals/FCon1000/raw/beijing/Beijing_Zang_demographics.txt", 
    berlin = "/home2/data/Originals/FCon1000/raw/berlin/Berlin_Margulies_demographics.txt", 
    cambridge = "/home2/data/Originals/FCon1000/raw/cambridge/Cambridge_Buckner_demographics.txt", 
    cleveland = "/home2/data/Originals/FCon1000/raw/cleveland/Cleveland_demographics.txt", 
    icbm = "/home2/data/Originals/FCon1000/raw/icbm/ICBM_demographics.txt", 
    leiden_a = "/home2/data/Originals/FCon1000/raw/leiden_a/Leiden_2180_demographics.txt", 
    leiden_b = "/home2/data/Originals/FCon1000/raw/leiden_b/Leiden_2200_demographics.txt", 
    munchen = "/home2/data/Originals/FCon1000/raw/munchen/Munchen_demographics.txt", 
    newark = "/home2/data/Originals/FCon1000/raw/newark/Newark_demographics.txt", 
    new_haven_b = "/home2/data/Originals/FCon1000/raw/new_haven_b/NewHaven_b_demographics.txt", 
    new_york_a_adhd = "/home2/data/Originals/FCon1000/raw/new_york_a_adhd/NewYork_a_ADHD_demographics.txt", 
    new_york_a = "/home2/data/Originals/FCon1000/raw/new_york_a/NewYork_a_demographics.txt", 
    new_york_b = "/home2/data/Originals/FCon1000/raw/new_york_b/NewYork_b_demographics.txt", 
    orangeburg = "/home2/data/Originals/FCon1000/raw/orangeburg/Orangeburg_demographics.txt", 
    queensland = "/home2/data/Originals/FCon1000/raw/queensland/Queensland_demographics.txt", 
    saint_louis = "/home2/data/Originals/FCon1000/raw/saint_louis/SaintLouis_demographics.txt", 
    QuironValencia = "/home2/data/Originals/QuironValencia/Quiron-Valencia_phenotypic.csv", 
    Rockland = "/home2/data/Originals/Rockland/NKI.1-39_phenotypic.csv", 
    VirginiaTech = "/home2/data/Originals/VirginiaTech/VTCRI_phenotypic.csv"
)
raw_phenotypes <- llply(files, function(f) {
    # cat(f, "\n")
    if (file_ext(f) == "csv")
        read.csv(f)
    else
        read.table(f)
})

# Eyes
eyes <- list(
    # note other scans BeijingEOEC are mixed but here i only preprocessed the 1st scan
    BeijingEOEC = "closed", 
    beijing = "closed", 
    QuironValencia = "open", 
    VirginiaTech = "open"
)
raw_phenotypes$Berlin$Eyes <- factor(raw_phenotypes$Berlin$Eyes, 
                                        labels=c("open", "closed"))
save(raw_phenotypes, file="raw_phenotypes.rda")

# Read in csv with links btw site and columns
col2phenos <- read.csv("/home2/data/Projects/CWAS/share/preprocessing/col2phenos.csv")

phenos <- ldply(names(files), function(site) {
    cat(site, "\n")
    
    i <- which(col2phenos$site == site)    

    sdf <- data.frame(
        site    = site, 
        id      = raw_phenotypes[[site]][[col2phenos$id[i]]], 
        age     = raw_phenotypes[[site]][[col2phenos$age[i]]], 
        sex     = raw_phenotypes[[site]][[col2phenos$sex[i]]]
    )
    
    if (is.na(col2phenos$handedness[i])) {
        sdf$handedness <- NA
    } else {
        sdf$handedness <- raw_phenotypes[[site]][[col2phenos$handedness[i]]]
    }
    
    if (!is.null(eyes[[site]])) {
        sdf$eyes <- eyes[[site]]
    } else if (!is.na(col2phenos$eyes[i])) {
        sdf$eyes <- raw_phenotypes[[site]][[col2phenos$eyes[i]]]
    } else {
        sdf$eyes <- NA
    }
    
    sdf
})

write.csv(phenos, file="xxx.csv")
