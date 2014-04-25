#!/usr/bin/env Rscript

# extract's the time-series from the brain-image
vcat <- function(msg, ...) cat(sprintf(msg, ...), "\n")


####


vcat("\nRead in user args")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("\nusage: 32_extract_ts.R [1 | 2 | 3]\n1=short, 2=medium, 3=long")

i <- as.numeric(args[1])

scans <- c("short", "medium", "long")
sets  <- c("40_Set1_N104", "40_Set1_N104", "40_Set2_N92")

scan <- scans[i]
set  <- sets[i]

nthreads <- 2


####


vcat("\nSet paths/settings")

strategy <- "compcor"

basedir   <- "/home2/data/Projects/CWAS"
subdir    <- file.path(basedir, "share/nki/subinfo", set)
func.list <- file.path(subdir, sprintf("%s_%s_funcpaths.txt", scan, strategy))
ts.list   <- file.path(subdir, sprintf("%s_%s_ts_peaks100_2mm.txt", scan, strategy))


####


vcat("\nRead input filenames and create/save output filenames")

func.files  <- as.character(read.table(func.list)[,1])
ts.files    <- as.character(read.table(ts.list)[,1])
func.masks  <- file.path(dirname(dirname(func.files)), 
                         "functional_brain_mask_to_standard.nii.gz")

if (!all(file.exists(func.masks))) stop("not all func masks exist")


####


vcat("\nLooping through files")

for (i in 1:length(func.files)) {
    func.file <- func.files[i]
    ts.file   <- ts.files[i]
    sca.dir   <- file.path(dirname(func.file), "sca")
    log.file  <- sprintf('qsub_logs/%s_sca_ts_sub%03i.log', scan, i)
    
    if (!file.exists(func.file) || !file.exists(ts.file)) {
        vcat("...input doesn't exist")
        next
    }
    dir.create(sca.dir, showWarnings=FALSE)
    
    cmd <- sprintf("./34_sca_ts.R %s %s %s", func.file, ts.file, nthreads)
    
    sfn   <- sprintf('qsub_scripts/%s_sca_ts_sub%03i.bash', scan, i)
    sfile <- "#!/usr/bash\n"
    sfile <- paste(sfile, cmd, sep="\n")
    cat(sfile, "\n", file=sfn)
    
    qcmd <- sprintf("qsub -S /bin/bash -pe mpi %i -V -cwd -o %s -j y %s", nthreads, log.file, sfn)
    vcat(qcmd)
    system(qcmd)
}
