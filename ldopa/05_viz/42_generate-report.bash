#!/bin/bash

rdir="/home2/data/Projects/CWAS/reports"
mkdir ${rdir}/figure_04 2> /dev/null
../../lib/x_knit.R 40_report-ldopa.Rmd ${rdir}/figure_04 report_ldopa
