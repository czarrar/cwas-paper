#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/ldopa"
outdir="${basedir}/ldopa"

echo "standard"

sdistdir="${outdir}/cwas/compcor_kvoxs_smoothed"

echo "...transforming distances"
curdir=$(pwd)
cd /home2/data/Projects/CWAS/share/lib
./transform_cor.R ${sdistdir}/subdist.desc 30 12
cd $curdir

echo "...deleting old mdmr results"
rm -r ${sdistdir}/ldopa_subjects+meanFD.mdmr

#echo "...archiving old mdmr results"
#archive="${sdistdir}/archive_old_sdists_and_perms"
#mkdir ${archive} 2> /dev/null
#mv ${sdistdir}/ldopa_subjects+meanFD.mdmr ${archive}/

echo "...MDMR"
connectir_mdmr.R -i ${outdir}/cwas/compcor_kvoxs_smoothed \
    --formula "subjects + conditions + meanFD" \
    --model ${indir}/subinfo/02_demo_with_gcors.csv \
    --factors2perm "conditions" \
    --strata "subjects" \
    --permutations 14999 \
    --forks 1 --threads 10 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    ldopa_subjects+meanFD.mdmr

#echo "standard with mean global"
#connectir_mdmr.R -i ${outdir}/cwas/compcor_kvoxs_smoothed \
#    --formula "subjects + conditions + meanFD + meanGcor" \
#    --model ${indir}/subinfo/02_demo_with_gcors.csv \
#    --factors2perm "conditions" \
#    --strata "subjects" \
#    --permutations 14999 \
#    --forks 1 --threads 10 \
#    --memlimit 12 \
#    --save-perms \
#    --ignoreprocerror \
#    ldopa_subjects+meanFD+meanGcor.mdmr

