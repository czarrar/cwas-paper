#!/usr/bin/env bash

if [[ "$#" -eq 0 ]]; then
    echo "usage: $0 strategy"
    echo "strategy: global or compcor"
    exit 1
fi

strategy=$1
study="adhd200_rerun"

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/${study}"
subdir="${indir}/subinfo"
outdir="${basedir}/${study}"
sdir="${outdir}/cwas/${strategy}_kvoxs_fwhm08"

# TDC vs ADHD-C
sdistdir="$sdir"

echo "...transforming distances"
curdir=$(pwd)
cd /home2/data/Projects/CWAS/share/lib
./transform_cor.R ${sdistdir}/subdist.desc 30 12
cd $curdir

echo "...deleting old mdmr results"
rm -r ${sdistdir}/adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr

#echo "...archiving old mdmr results"
#archive="${sdistdir}/archive_old_sdists_and_perms"
#mkdir ${archive} 2> /dev/null
#mv ${sdistdir}/adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr ${archive}/

echo "...MDMR"
connectir_mdmr.R -i ${sdir} \
    --formula "diagnosis + run + sex + age + iq + mean_FD" \
    --model ${subdir}/30_subjects_matched_combined.csv \
    --factors2perm "diagnosis" \
    --permutations 14999 \
    --forks 1 --threads 12 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    adhd_vs_tdc_run+gender+age+iq+mean_FD.mdmr

## with meanGcor
#connectir_mdmr.R -i ${sdir} \
#    --formula "diagnosis + run + sex + age + iq + mean_FD + meanGcor" \
#    --model ${subdir}/30_subjects_matched_combined_meanGcor.csv \
#    --factors2perm "diagnosis" \
#    --permutations 14999 \
#    --forks 1 --threads 12 \
#    --memlimit 12 \
#    --save-perms \
#    --ignoreprocerror \
#    adhd_vs_tdc_run+gender+age+iq+mean_FD+meanGcor.mdmr
