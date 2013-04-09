"""
This script will compile a new data frame including
the demographics as well as the anatomical/functional paths
"""

###
# Inputs
###

# Variables
pipeline <- "_compcor_ncomponents_5_linear1.motion1.compcor1.CSF_0.98_GM_0.7_WM_0.98"
pipe.name <- "compcor"

# Read in Demographics
demofile <- "/home/data/Projects/CWAS/share/ldopa/subinfo/01_demo.csv"
demo <- read.csv(demofile)

# Directory Paths
pdir <- sprintf("/home2/data/PreProc/LDOPA/sym_links/pipeline_0/%s", pipeline)
sdirs <- file.path(pdir, sprintf("s%i_", unique(demo$subjects)))
anatdirs <- file.path(sdirs, "scan")
ldopadirs <- file.path(sdirs, "scan_ldopa_func")
placebodirs <- file.path(sdirs, "scan_placebo_func")

# File Paths
subpath <- "func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz"
anatfiles <- file.path(anatdirs, "anat/mni_normalized_anatomical.nii.gz")
ldopafiles <- file.path(ldopadirs, subpath)
placebofiles <- file.path(placebodirs, subpath)

# Check
all(file.exists(anatfiles))
all(file.exists(ldopafiles))
all(file.exists(placebofiles))


###
# NEW Dataframe
###

# Combine
new.demo <- demo
new.demo$anat <- rep(anatfiles, each=2)
new.demo$func <- NA
new.demo$func[new.demo$conditions=="ldopa"] <- ldopafiles
new.demo$func[new.demo$conditions=="placebo"] <- placebofiles


###
# Outputs
###

# Paths
odir <- "/home2/data/Projects/CWAS/share/ldopa/subinfo"
newdemofile <- file.path(odir, "02_demo_withpaths.csv")
ldopafile <- file.path(odir, "02_ldopa_funcpaths.txt")
placebofile <- file.path(odir, "02_placebo_funcpaths.txt")
allfile <- file.path(odir, "02_all_funcpaths.txt")

# Save
write.csv(new.demo, file=newdemofile)
write.table(ldopafiles, file=ldopafile, row.names=F, col.names=F)
write.table(placebofiles, file=placebofile, row.names=F, col.names=F)
write.table(new.demo$func, file=allfile, row.names=F, col.names=F)


