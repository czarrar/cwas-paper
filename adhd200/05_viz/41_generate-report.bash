#!/bin/bash

# Generate report page
# see http://czarrar.github.com/cwas-paper/fig_04/report_surfaces.html
# after doing git commit and push
rdir="/home2/data/Projects/CWAS/reports"
mkdir ${rdir}/figure_04 2> /dev/null
../../lib/x_knit.R 40_report-adhd.Rmd ${rdir}/figure_04 report_adhd
