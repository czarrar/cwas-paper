#!/bin/bash

# Generate report page
# see http://czarrar.github.com/cwas-paper/30_robustness/report_age_effects.html
# after doing git commit and push
rdir="/home2/data/Projects/CWAS/reports"
mkdir ${rdir}/figure_02 2> /dev/null
../../../lib/x_knit.R E-31_report_ages.Rmd ${rdir}/figure_02 report_age_effects
