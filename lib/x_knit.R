#!/home/data/PublicProgram/R/bin/Rscript --vanilla

args <- commandArgs(TRUE)

if (length(args) != 2) {
    cat("x_knit.R script.Rmd outdir\n")
    quit(status=1)
}
    
library(tools)
library(knitr)

opts_knit$set(out.format = "html")
thm <- knit_theme$get('acid')
knit_theme$set(thm)

infile <- file_path_as_absolute(args[1])
if (file_ext(infile) != "Rmd") stop("Input file must have extension .Rmd")
#stylesheet <- file_path_as_absolute('foundation/stylesheets/foundation.css')

outdir <- file_path_as_absolute(args[2])
if (!file.exists(outdir))
    dir.create(outdir)
outfile <- paste(outdir, "/", file_path_sans_ext(basename(infile)), ".html", sep="")
setwd(outdir)

#knit2html(infile, output=outfile, stylesheet=stylesheet)
knit2html(infile, output=outfile)
