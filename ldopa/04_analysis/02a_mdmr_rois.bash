#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/ldopa"
outdir="${basedir}/ldopa"

echo "standard"

echo "Age"
sdistdir="${outdir}/cwas/rois_random_k0800_only"

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

echo "...mdmr"
connectir_mdmr.R -i ${sdistdir} \
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
#connectir_mdmr.R -i ${outdir}/cwas/rois_random_k0800_only \
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

###
# CORRECT
###

cd /home2/data/Projects/CWAS/share/lib/clustcor

sdir="${outdir}/cwas/rois_random_k0800_only"
roidir="${outdir}/rois"

# Only ROI-based
#ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
ks="0800"
for k in ${ks}; do
    echo "K of ${k}"
    
    sdistdir="${sdir}"
    mdmrdir="${sdistdir}/ldopa_subjects+meanFD.mdmr"
    roifile="${roidir}/rois_random_k${k}.nii.gz"
    
    ./le_correcter.R ${sdistdir} ${mdmrdir} ${roifile}
done
