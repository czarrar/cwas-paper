#!/bin/bash

# Generate report page
# see http://czarrar.github.com/cwas-paper/50_dev-motion/report_surfaces.html
# after doing git commit and push
rdir="/home2/data/Projects/CWAS/reports"
mkdir ${rdir}/40_compare-glm 2> /dev/null
../../../lib/x_knit.R E-11_Results.Rmd ${rdir}/40_compare-glm report_scatter_plots

