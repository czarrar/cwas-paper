# Gather subject phenotypic data

## @knitr setup
library(plyr)
library(tools)

## @knitr gather-files
# for beijing only use session 1
# note: for ann arbor, line 16 or sub49687, the handedness was adjusted from L to B (for ambidextrous)
# nore: for vtech, I removed the first line that indicated the scan num associated with sleep status and incoporated it into the 2nd (now 1st) line
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


## @knitr fixes

# Fix Virgina Tech which has the code labels for certain columns as additional rows
raw_phenotypes$VirginiaTech <- raw_phenotypes$VirginiaTech[1:25,]

# Remove the 1 subject from Berlin missing Age information
raw_phenotypes$Berlin <- raw_phenotypes$Berlin[raw_phenotypes$Berlin$New.Age.Scan<500,]

# Pad subject ID by 3 for Berlin
raw_phenotypes$Berlin$INDI.ID <- sprintf("%07i", raw_phenotypes$Berlin$INDI.ID)

# Pad subject ID by 2 for QuironValencia
raw_phenotypes$QuironValencia$ID <- sprintf("%07i", raw_phenotypes$QuironValencia$ID)


## @knitr eyes
eyes <- list(
    # note other scans BeijingEOEC are mixed but here i only preprocessed the 1st scan
    BeijingEOEC = "closed", 
    beijing = "closed", 
    QuironValencia = "open", 
    VirginiaTech = "open"
)
raw_phenotypes$Berlin$Eyes.Opened.Closed <- factor(raw_phenotypes$Berlin$Eyes.Opened.Closed, 
                                                labels=c("open", "closed"))

## @knitr col2phenos
# Read in csv with links btw site and columns
col2phenos <- read.csv("/home2/data/Projects/CWAS/share/preprocessing/col2phenos.csv")

## @knitr combine-phenos
phenos <- ldply(names(files), function(site) {
    i <- which(col2phenos$site == site)    

    sdf <- data.frame(
        site    = site, 
        id      = as.character(raw_phenotypes[[site]][[col2phenos$id[i]]]), 
        age     = as.numeric(raw_phenotypes[[site]][[col2phenos$age[i]]]), 
        sex     = raw_phenotypes[[site]][[col2phenos$sex[i]]]
    )
    
    if (is.na(col2phenos$handedness[i])) {
        sdf$handedness <- NA
    } else {
        sdf$handedness <- as.character(raw_phenotypes[[site]][[col2phenos$handedness[i]]])
    }
    
    if (!is.null(eyes[[site]])) {
        sdf$eyes <- eyes[[site]]
    } else if (!is.na(col2phenos$eyes[i])) {
        sdf$eyes <- as.character(raw_phenotypes[[site]][[col2phenos$eyes[i]]])
    } else {
        sdf$eyes <- NA
    }
    
    sdf
})

# Fix differences in sex (not literally)
phenos$sex <- factor(substr(toupper(phenos$sex), 1, 1))

# Fix differences in handedness codes
h <- substr(toupper(phenos$handedness), 1, 1)
h[h=="B"] <- "A"
h[h=="U"] <- NA
phenos$handedness <- factor(h)

# Factorize eyes
phenos$eyes <- factor(phenos$eyes)

# Save
write.csv(phenos, file="/home2/data/Projects/CWAS/share/subinfo/02_phenos.csv")
